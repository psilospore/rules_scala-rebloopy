package io.bazel.rules_scala.bloop

import java.io.{File, InputStream}
import java.nio.file.{FileSystems, Files, Path, Paths}
import java.util.concurrent.{Executors, TimeUnit}
import com.github.plokhotnyuk.jsoniter_scala.core._

import bloop.bloopgun.core.Shell
import bloop.config.Config.Scala
import bloop.config.ConfigCodecs._
import bloop.config.{Config => BloopConfig}
import bloop.launcher.bsp.BspBridge
import bloop.launcher.{Launcher => BloopLauncher}
import ch.epfl.scala.bsp4j._
import com.google.gson.Gson
import io.bazel.rulesscala.jar.JarCreator
import io.bazel.rulesscala.worker.Worker
import net.sourceforge.argparse4j.ArgumentParsers
import net.sourceforge.argparse4j.impl.Arguments
import net.sourceforge.argparse4j.inf.{ArgumentParser, Namespace}
import org.apache.commons.io.FileUtils
import org.eclipse.lsp4j.jsonrpc.{Launcher => LspLauncher}

import scala.collection.JavaConverters._
import scala.compat.java8.FutureConverters._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration.Duration
import scala.concurrent.{Await, Promise}
import zio._
import zio.console._
import zio.clock.Clock
import zio.duration._

import scala.collection.mutable

trait BloopServer extends BuildServer with ScalaBuildServer

trait Errors extends RuntimeException
object StatusCodeNotOk extends Errors
object UnexpectedRefError extends Errors

//TODO move out?
object BloopUtil {

  class BloopExtraBuildParams() {
    val ownsBuildFiles: Boolean = true
  }

  //At the moment just print results
  def buildClient: BuildClient = new BuildClient {

    def afterBuildTaskFinish(bti: String) = {
      println("afterBuildTaskFinish", bti)
    }

    override def onBuildShowMessage(params: ShowMessageParams): Unit = println("onBuildShowMessage", params)

    override def onBuildLogMessage(params: LogMessageParams): Unit = println("onBuildLogMessage", params)

    override def onBuildTaskStart(params: TaskStartParams): Unit = println("onBuildTaskStart", params)

    override def onBuildTaskProgress(params: TaskProgressParams): Unit = println("onBuildTaskProgress", params)

    override def onBuildTaskFinish(params: TaskFinishParams): Unit = {
      println("onBuildTaskFinish", params)
    }

    override def onBuildPublishDiagnostics(params: PublishDiagnosticsParams): Unit = println("onBuildPublishDiagnostics", params)

    override def onBuildTargetDidChange(params: DidChangeBuildTarget): Unit = println("onBuildTargetDidChange", params)
  }

  def initBloop(packageDir: String): BloopServer = {
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

    (BloopLauncher.connectToBloopBspServer("1.4.3", false, bspBridge, List()) match {
      case Right(Right(Some(socket))) => {
        val es = Executors.newCachedThreadPool()
        val launcher = new LspLauncher.Builder[BloopServer]()
          .setRemoteInterface(classOf[BloopServer])
          .setExecutorService(es)
          .setInput(socket.getInputStream)
          .setOutput(socket.getOutputStream)
          .setLocalService(buildClient)
          .create()

        launcher.startListening()
        val bloopServer = launcher.getRemoteProxy

        buildClient.onConnectWithServer(bloopServer)

        System.err.println(s"attempting build initialize for $packageDir")

        val initBuildParams = {
          val p = new InitializeBuildParams(
            "bazel",
            "1.3.4",
            "2.0.0-M11",
            packageDir,
            new BuildClientCapabilities(List("scala").asJava)
          )
          val gson = new Gson()
          p.setData(gson.toJsonTree(new BloopExtraBuildParams()))
          p
        }

        //TODO ZIO
        Await.resul(bloopServer.buildInitialize(initBuildParams).toScala.map(initializeResults => {
          System.err.println(s"initialized: Results $initializeResults")
          bloopServer.onBuildInitialized()
        }), Duration.Inf)

        Some(bloopServer)
      }
      case a@_ => {
        println(s"Unexpected case ${a}")
        None
      }

    }).get
  }
}

//TODO move
object WorkerUtils {

  def getOrUpdateMapRef[K, V](ref: Ref[Map[K, V]], k: K, ifNone: => V): Task[V] =
    for {
      map <- ref.get
      maybeV = map.get(k)
      v <- maybeV.fold({
        println("hi")
        val v = ifNone
        ref.update(_ + (k -> v)) *> ZIO(v)
      })((v) => ZIO(v))
    } yield {
      v
    }

  /**
   * namespace.getList[File] gives me an error so I wrote this
   * @param str
   */
  def parseFileList(namespace: Namespace, key: String): List[Path] = {
    Option(namespace.getString(key)).fold(
      List[Path]()
    )(
      _.split(", ").toList.map(
        relPath => Paths.get(s"$pwd/$relPath").toAbsolutePath //.toRealPath()
      )
    )
  }

  /**
   * Parse the jars needed for the scala compiler from the classpath.
   * The jars needed are specified in BUILD
   */
  def getScalaJarsFromCP(): (List[Path], String) = {
    val scalaCPs = Set("io_bazel_rules_scala_scala_compiler", "io_bazel_rules_scala_scala_library", "io_bazel_rules_scala_scala_reflect", "io_bazel_rules_scala_scala_xml")
    val classPaths = System.getProperty("java.class.path").split(":").toList
    val paths = classPaths.filter(cp => scalaCPs.exists(cp.contains)).map(s => Paths.get(s"$pwd/$s").toRealPath())

    val re = raw".*scala-.*-(2.*).jar".r
    val version = paths.head.toString match {
      case re(s) => s
    }

    (paths, version)
  }

  private val pwd = {
    val uncleanPath = FileSystems.getDefault().getPath(".").toAbsolutePath.toString
    uncleanPath.substring(0, uncleanPath.size - 2)
  }

  def buildArgParser: ArgumentParser = {
    val parser = ArgumentParsers.newFor("bloop").addHelp(true).defaultFormatWidth(80).fromFilePrefix("@").build
    //Example    --label ABC:A --sources ABC/A.scala --targetClasspath external/io_bazel_rules_scala_scala_library/scala-library-2.12.10.jar, external/io_bazel_rules_scala_scala_reflect/scala-reflect-2.12.10.jar --manifest bazel-out/darwin-fastbuild/bin/ABC/A_MANIFEST.MF --jarOut bazel-out/darwin-fastbuild/bin/ABC/A.jar --statsfile bazel-out/darwin-fastbuild/bin/ABC/A.statsfile --bloopProjectConfig ABC/BUILD --bloopProjectOutput ABC/BUILD
    parser.addArgument("--label").required(true)
    parser.addArgument("--sources").`type`(Arguments.fileType)
    parser.addArgument("--targetClasspath").`type`(Arguments.fileType)
    parser.addArgument("--manifest").`type`(Arguments.fileType)
    parser.addArgument("--jarOut").`type`(Arguments.fileType)
    parser.addArgument("--statsfile").`type`(Arguments.fileType)
    parser.addArgument("--bloopProjectConfig").`type`(Arguments.fileType)
    parser.addArgument("--bloopProjectOutput").`type`(Arguments.fileType)
    parser.addArgument("--bloopDependencies")
    parser
  }

}


object BloopWorker extends Worker.Interface {
  import WorkerUtils._

  def main(args: Array[String]): Unit = {
    System.err.println("main")
    Worker.workerMain(args, BloopWorker)
  }

  //TODO just don't use this safe map
  //val bloopServersByPackageRef: Ref[Map[String, BloopServer]] = Runtime.global.unsafeRun(Ref.make(Map[String, BloopServer]()))
  val bloopServersByPackageRef: mutable.Map[String, BloopServer] = mutable.Map[String, BloopServer]()

  //Implements bazel worker interface so work is called externally. I will create or get a bloop server the given package
  def work(args: Array[String]) {
    System.err.println("WHATTTTTT")
    System.err.println(args.mkString(" "))

    var argsArrayBuffer = scala.collection.mutable.ArrayBuffer[String]()
    for (i <- args.indices) {
      argsArrayBuffer += args(i)
    }

    val namespace = buildArgParser.parseArgsOrFail(argsArrayBuffer.toArray)

    //TODO can I make all of this an environment or just put it in a case class
    val label = namespace.getString("label")
    val srcs = parseFileList(namespace, "sources")
    val classpath = parseFileList(namespace, "targetClasspath")
    val bloopProjectConfig = namespace.get[File]("bloopProjectConfig").toPath

    val bloopOutDir = namespace.get[File]("bloopProjectOutput").toPath
    val manifestPath = namespace.getString("manifest")
    val jarOut = namespace.getString("jarOut")
    val statsfile = namespace.get[File]("statsfile").toPath
    val bloopDependencies = Option(namespace.get[String]("bloopDependencies"))
      .map(_.split(", ").toList).getOrElse(List())

    System.err.println(s"WORKER Compiling $label")

    val packageDir = bloopOutDir.resolve("../../")
    val projectClassesDir = bloopOutDir.resolve("classes")

    // TODO I could do this
    // val info = getInfo(namespace)
    // generateBloopConfig(info)
    // compile(info)
    // copyJar(info)

    def generateBloopConfig: Task[Path] = ZIO.effect({
      Files.createDirectories(projectClassesDir)
      val (scalaJars, scalaVersion) = getScalaJarsFromCP()

      val bloopConfig = BloopConfig.File(
        version = BloopConfig.File.LatestVersion,
        project = BloopConfig.Project(
          name = label,
          directory = packageDir,
          workspaceDir = None, //TODO this is new
          sources = srcs.map(_.toRealPath()),
          sourcesGlobs = None, //TODO this is new
          sourceRoots = None, //TODO this is new
          tags = None, //TODO this is new
          dependencies = bloopDependencies,
          classpath = classpath,
          out = bloopOutDir,
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
          resolution = None,
        )
      )

      val outputStream = Files.newOutputStream(bloopProjectConfig)
      writeToStream(bloopConfig, outputStream)
      outputStream.close()

      bloopProjectConfig
    })

    def compile(bloopServer: BloopServer): Task[CompileResult] = {
      val buildTargetId = List(new BuildTargetIdentifier(s"file://$packageDir/?id=$label"))
      System.err.println(s"Attempt compile for $buildTargetId")
      val compileParams = new CompileParams(buildTargetId.asJava)
      ZIO.fromCompletionStage(bloopServer.buildTargetCompile(compileParams)).filterOrFail(_.getStatusCode != StatusCode.OK)(StatusCodeNotOk)
    }

    def copyJar: Task[Unit] = ZIO.effect({
      val tempJarFiles = Files.createTempDirectory(s"$label-jar")
      FileUtils.copyDirectory(projectClassesDir.toFile, tempJarFiles.toFile, true)
      JarCreator.buildJar(Array("-m", manifestPath, jarOut, tempJarFiles.toString))
    })

    def writeStatsFile(time: Long): Task[Path] = ZIO.effect({Files.write(statsfile, s"build_time=$time".getBytes)})

    val packageDirStr = packageDir.toString
    def getTime: ZIO[Clock, Nothing, Long] = ZIO.accessM[Clock] { x => x.get.currentTime(TimeUnit.MILLISECONDS) } //TODO delete

    val bloopServer = bloopServersByPackageRef.getOrElseUpdate(packageDirStr, {BloopUtil.initBloop(packageDirStr)})

    val program: ZIO[Clock with Console, Throwable, Unit] = for {
      totalTime <- (generateBloopConfig *> compile(bloopServer) *> copyJar).timed
      _ <- writeStatsFile(totalTime._1.toMillis)
      _ <- ZIO.sleep(1.seconds) //TODO don't do this
    } yield { () } //TODO

    Runtime.global.unsafeRun(program.provideLayer(Clock.live and Console.live))

  }
}