package io.bazel.rules_scala.bloop

import java.io.{File, InputStream}
import java.nio.file.{FileSystems, Files, Path, Paths}
import java.util
import java.util.concurrent.Executors

import bloop.config.Config.Scala
import bloop.config.{Config => BloopConfig}
import bloop.launcher.bsp.BspBridge
import bloop.bloopgun.core.Shell
import bloop.launcher.{Launcher => BloopLauncher}
import ch.epfl.scala.bsp4j._
//import io.bazel.rulesscala.jar.{JarCreator, JarHelper}
import io.bazel.rulesscala.worker.{GenericWorker, Processor}
import net.sourceforge.argparse4j.ArgumentParsers
import net.sourceforge.argparse4j.impl.Arguments
import net.sourceforge.argparse4j.inf.Namespace
import org.eclipse.lsp4j.jsonrpc.{Launcher => LspLauncher}

import scala.collection.JavaConverters._
import scala.compat.java8.FutureConverters._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration.Duration
import scala.concurrent.{Await, Promise}


trait BloopServer extends BuildServer with ScalaBuildServer


object BloopUtil {
  //At the moment just print results
  val printClient = new BuildClient {
    override def onBuildShowMessage(params: ShowMessageParams): Unit = println("onBuildShowMessage", params)

    override def onBuildLogMessage(params: LogMessageParams): Unit = println("onBuildLogMessage", params)

    override def onBuildTaskStart(params: TaskStartParams): Unit = println("onBuildTaskStart", params)

    override def onBuildTaskProgress(params: TaskProgressParams): Unit = println("onBuildTaskProgress", params)

    //TODO handle this probably contains class files and I might write it to .bloop/out/classes/ then other bazel targets can point to this if this is a dep
    override def onBuildTaskFinish(params: TaskFinishParams): Unit = {
      println("onBuildTaskFinish", params)
    }

    override def onBuildPublishDiagnostics(params: PublishDiagnosticsParams): Unit = println("onBuildPublishDiagnostics", params)

    override def onBuildTargetDidChange(params: DidChangeBuildTarget): Unit = println("onBuildTargetDidChange", params)
  }

  def initBloop(): BloopServer = {
    val emptyInputStream = new InputStream() {
      override def read(): Int = -1
    }

    val dir = Files.createTempDirectory(s"bsp-launcher")
    val bspBridge = new BspBridge(
      emptyInputStream,
      System.err,
      Promise[Unit](),
      System.err,
      Shell.default,
      dir
    )

    //TODO move to init we get a work request in sequence A, B, C, C_run
    BloopLauncher.connectToBloopBspServer("1.1.2", false, bspBridge, List()) match {
      case Right(Right(Some(socket))) => {
        val es = Executors.newCachedThreadPool()

        val launcher = new LspLauncher.Builder[BloopServer]()
          .setRemoteInterface(classOf[BloopServer])
          .setExecutorService(es)
          .setInput(socket.getInputStream)
          .setOutput(socket.getOutputStream)
          .setLocalService(printClient)
          .create()

        launcher.startListening()
        val bloopServer = launcher.getRemoteProxy

        printClient.onConnectWithServer(bloopServer)

        System.err.println("attempting build initialize")

        val initBuildParams = new InitializeBuildParams(
          "bsp",
          "1.3.4",
          "2.0",
          s"file:///Users/syedajafri/dev/bazelExample", //TODO don't hardcode
          new BuildClientCapabilities(List("scala").asJava)
        )


        Await.result(bloopServer.buildInitialize(initBuildParams).toScala.map(initializeResults => {
          System.err.println(s"initialized: Results $initializeResults")
          bloopServer.onBuildInitialized()
        }), Duration.Inf)

        bloopServer

      }
    }
  }

}

object BloopRunner extends GenericWorker(new BloopProcessor({
  BloopUtil.initBloop()
})) {

  def main(args: Array[String]) {
    run(args)
  }

}

class BloopProcessor(bloopServer: BloopServer) extends Processor {

  private val pwd = {
    val uncleanPath = FileSystems.getDefault().getPath(".").toAbsolutePath.toString
    uncleanPath.substring(0, uncleanPath.size - 2)
  }

  /**
   * namespace.getList[File] is bonked
   *
   * @param str
   */
  private def parseFileList(namespace: Namespace, key: String): List[Path] = {
    Option(namespace.getString(key)).fold(
      List[Path]()
    )(
      _.split(", ").toList.map(
        relPath => Paths.get(s"$pwd/$relPath").toRealPath()
      )
    )
  }


  /**
   * Fetch the jars needed for the scala compiler from the classpath.
   * The jars needed are specified in BUILD
   * TODO different versions need additional libraries like JLine
   */
  private def getScalaJarsFromCP(): (List[Path], String) = {
    val scalaCPs = Set("io_bazel_rules_scala_scala_compiler", "io_bazel_rules_scala_scala_library", "io_bazel_rules_scala_scala_reflect", "io_bazel_rules_scala_scala_xml")
    val classPaths = System.getProperty("java.class.path").split(":").toList
    val paths = classPaths.filter(cp => scalaCPs.exists(cp.contains)).map(s => Paths.get(s"$pwd/$s").toRealPath())

    val re = raw".*scala-.*-(2.*).jar".r
    val version = paths.head.toString match {case re(s) => s}

    (paths, version)
  }

  //Does this run once per target? if so create a bloop config and create compile request here
  override def processRequest(args: util.List[String]) = {
    var argsArrayBuffer = scala.collection.mutable.ArrayBuffer[String]()
    for (i <- 0 to args.size - 1) {
      argsArrayBuffer += args.get(i)
    }

    System.err.println(s"Process request $args")

    val parser = ArgumentParsers.newFor("bloop").addHelp(true).defaultFormatWidth(80).fromFilePrefix("@").build
    parser.addArgument("--label").required(true)
    parser.addArgument("--sources").`type`(Arguments.fileType)
    parser.addArgument("--target_classpath").`type`(Arguments.fileType)
    parser.addArgument("--build_file_path").`type`(Arguments.fileType)
    parser.addArgument("--bloopDir").`type`(Arguments.fileType)
    parser.addArgument("--output").`type`(Arguments.fileType)

    val namespace = parser.parseArgsOrFail(argsArrayBuffer.toArray)

    val output = namespace.get[File]("output").toPath
    val label = namespace.getString("label")
    val srcs = parseFileList(namespace, "sources")
    val classpath = parseFileList(namespace, "target_classpath")
    val workspaceDir = namespace.get[File]("bloopDir").toPath

    val bloopDir = workspaceDir.resolve(".bloop").toAbsolutePath
    val bloopOutDir = bloopDir.resolve("out").toAbsolutePath
    val projectOutDir = bloopOutDir.resolve(label).toAbsolutePath
    val projectClassesDir = projectOutDir.resolve("classes").toAbsolutePath
    val bloopConfigPath = bloopDir.resolve(s"$label.json")
    Files.createDirectories(projectClassesDir)

    val (scalaJars, scalaVersion) = getScalaJarsFromCP()

    val bloopConfig = BloopConfig.File(
      version = BloopConfig.File.LatestVersion,
      project = BloopConfig.Project(
        name = label,
        directory = workspaceDir,
        sources = srcs,
        dependencies = List(), //TODO would be ABC:A for ABC:B
        classpath = classpath,
        out = projectOutDir,
        classesDir = projectClassesDir,
        resources = None,
        `scala` = Some(Scala(
          "org.scala-lang",
          "scala-compiler",
          scalaVersion,
          List(),
          scalaJars,
          None,
          None
        )),
        java = None,
        sbt = None,
        test = None,
        platform = None,
        resolution = None
      )
    )


    Files.write(bloopConfigPath, bloop.config.toStr(bloopConfig).getBytes)

    val buildTargetId = List(new BuildTargetIdentifier(s"file://$workspaceDir?id=$label"))
    val compileParams = new CompileParams(buildTargetId.asJava)

    Await.result(bloopServer.buildTargetCompile(compileParams).toScala, Duration.Inf)

    Files.write(output, s"--generatedClasses\n$projectClassesDir".getBytes)
  }
}