package io.bazel.rules_scala.bloop

import java.io.{File, InputStream}
import java.nio.file.{FileSystems, Files, Path, Paths}
import java.util
import java.util.concurrent.Executors

import bloop.config.Config.Scala
import io.bazel.rulesscala.worker.{GenericWorker, Processor}
import net.sourceforge.argparse4j.ArgumentParsers
import net.sourceforge.argparse4j.impl.Arguments
import bloop.config.{Config => BloopConfig}
import bloop.launcher.LauncherStatus.SuccessfulRun
import bloop.launcher.{Launcher => BloopLauncher}
import bloop.launcher.bsp.BspBridge
import bloop.launcher.core.Shell
import ch.epfl.scala.bsp4j.{BuildClient, BuildServer, DidChangeBuildTarget, LogMessageParams, PublishDiagnosticsParams, ScalaBuildServer, ShowMessageParams, TaskFinishParams, TaskProgressParams, TaskStartParams}
import org.eclipse.lsp4j.jsonrpc.{Launcher => LspLauncher}
import ch.epfl.scala.bsp4j._
import bloop.config.{Config => BloopConfig}
import bloop.launcher.LauncherStatus.SuccessfulRun
import bloop.launcher.{Launcher => BloopLauncher}
import bloop.launcher.bsp.BspBridge
import net.sourceforge.argparse4j.inf.Namespace
import org.eclipse.lsp4j.jsonrpc.{Launcher => LspLauncher}

import scala.compat.java8.FutureConverters._
import scala.collection.JavaConverters._
import scala.concurrent.Promise
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Promise
import scala.concurrent.duration.Duration
import scala.io.Codec
import scala.util.Try

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

        bloopServer.buildInitialize(initBuildParams).toScala.map(initializeResults => {
          System.err.println(s"initialized: Results $initializeResults")
          bloopServer.onBuildInitialized()
        })

        bloopServer

      }
    }
  }

}

object BloopRunner extends GenericWorker(new BloopProcessor({BloopUtil.initBloop()})) {

  def main(args: Array[String]) {
    run(args)
  }

}

class BloopProcessor(bloopServer: BloopServer) extends Processor {

  /**
   * namespace.getList[File] is bonked
   *
   * @param str
   */
  private def parseFileList(namespace: Namespace, key: String): List[Path] = {
    val pwd = {
      val uncleanPath = FileSystems.getDefault().getPath(".").toAbsolutePath.toString
      uncleanPath.substring(0, uncleanPath.size - 2)
    }
    Option(namespace.getString(key)).fold(
      List[Path]()
    )(
      _.split(", ").toList.map(
        relPath => Paths.get(s"$pwd/$relPath").toRealPath()
      )
    )
  }

  //Does this run once per target? if so create a bloop config and create compile request here
  override def processRequest(args: util.List[String]) = {
    var argsArrayBuffer = scala.collection.mutable.ArrayBuffer[String]()
    for (i <- 0 to args.size - 1) {
      argsArrayBuffer += args.get(i)
    }

    System.err.println(s"Process request $args")

    //TODO could pass in everything needed for creating bloop config
    val parser = ArgumentParsers.newFor("bloop").addHelp(true).defaultFormatWidth(80).fromFilePrefix("@").build
    parser.addArgument("--label").required(true)
    parser.addArgument("--sources").`type`(Arguments.fileType)
    parser.addArgument("--target_classpath").`type`(Arguments.fileType)
    parser.addArgument("--compiler_classpath")
    parser.addArgument("--build_file_path").`type`(Arguments.fileType)
    parser.addArgument("--bloopDir").`type`(Arguments.fileType)

    val namespace = parser.parseArgsOrFail(argsArrayBuffer.toArray)

    val label = namespace.getString("label")
    val compilerClasspath = Paths.get("/private/var/tmp/_bazel_syedajafri/ad86228950bcb07c687f46ad51824bd1/external/io_bazel_rules_scala_scala_compiler/scala-compiler-2.12.10.jar") ::
      parseFileList(namespace, "compiler_classpath") //TODO just has lib and reflect
    val srcs = parseFileList(namespace, "sources")
    val classpath = parseFileList(namespace, "target_classpath")

    //    System.err.println(srcs.toAbsolutePath)

    System.err.println(label)
    System.err.println(srcs)

    val workspaceDir = namespace.get[File]("bloopDir").toPath
    val bloopDir = workspaceDir.resolve(".bloop").toAbsolutePath
    val bloopOutDir = bloopDir.resolve("out").toAbsolutePath
    val projectOutDir = bloopOutDir.resolve(label).toAbsolutePath
    val projectClassesDir = projectOutDir.resolve("classes").toAbsolutePath
    val bloopConfigPath = bloopDir.resolve(s"$label.json")
    Files.createDirectories(projectClassesDir)

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
          "2.12.12", //TODO
          List(),
          compilerClasspath,
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

    System.err.println("writing to " + bloop.config.toStr(bloopConfig))
    System.err.println(bloopConfigPath)

    Files.write(bloopConfigPath, bloop.config.toStr(bloopConfig).getBytes)

  }
}