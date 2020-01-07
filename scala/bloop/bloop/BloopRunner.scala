package io.bazel.rules_scala.bloop

import java.io.{File, InputStream}
import java.nio.file.Files
import java.util
import java.util.concurrent.Executors

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
import org.eclipse.lsp4j.jsonrpc.{Launcher => LspLauncher}

import scala.compat.java8.FutureConverters._
import scala.collection.JavaConverters._
import scala.concurrent.Promise
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Promise
import scala.io.Codec
import scala.util.Try


trait BloopServer extends BuildServer with ScalaBuildServer

object BloopRunner extends GenericWorker(new BloopProcessor){
  private[this] var bloopServer: BloopServer = null

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

  def main(args: Array[String]) {
//    println("blooprunner")
    initBloop()
    run(args)
  }

  def initBloop(): Unit = {
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
        bloopServer = launcher.getRemoteProxy

        printClient.onConnectWithServer(bloopServer)

        System.err.println("attempting build initialize")

        val initBuildParams = new InitializeBuildParams(
          "bsp",
          "1.3.4",
          "2.0",
          s"file:///Users/syedajafri/dev/bazelExample", //TODO don't hardcode
          new BuildClientCapabilities(List("scala").asJava)
        )

        bloopServer.buildInitialize(initBuildParams).toScala.foreach(initializeResults => {
          System.err.println(s"initialized: Results $initializeResults")
          bloopServer.onBuildInitialized()
        })

      }
    }
  }
}

class BloopProcessor extends Processor {

  //Does this run once per target? if so create a bloop config and create compile request here
  override def processRequest(args: util.List[String]): Unit = {
    var argsArrayBuffer = scala.collection.mutable.ArrayBuffer[String]()
    for (i <- 0 to args.size-1) {
      argsArrayBuffer += args.get(i)
    }

    System.err.println("HELLO")

    //TODO could pass in everything needed for creating bloop config
    val parser = ArgumentParsers.newFor("bloop").addHelp(true).defaultFormatWidth(80).fromFilePrefix("@").build
//    parser.addArgument("--flagfile").`type`(Arguments.fileType)
//    parser.addArgument("output").`type`(Arguments.fileType)
//    parser.addArgument("--config").required(true).`type`(Arguments.fileType)
    parser.addArgument("--label").required(true)


    val namespace = parser.parseArgsOrFail(argsArrayBuffer.toArray)

    val label = namespace.getString("--label")
    System.err.println(label)

  }
}