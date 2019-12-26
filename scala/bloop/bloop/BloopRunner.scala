package io.bazel.rules_scala.bloop

import java.io.File
import java.util

import io.bazel.rulesscala.worker.{GenericWorker, Processor}
import net.sourceforge.argparse4j.ArgumentParsers
import net.sourceforge.argparse4j.impl.Arguments

import bloop.config.{Config => BloopConfig}
import bloop.launcher.LauncherStatus.SuccessfulRun
import bloop.launcher.{Launcher => BloopLauncher}
import bloop.launcher.bsp.BspBridge
import org.eclipse.lsp4j.jsonrpc.{Launcher => LspLauncher}

import scala.io.Codec

//TODO consider dedup with ScalaFmtRunner

object BloopRunner extends GenericWorker(new BloopProcessor){
  def main(args: Array[String]) {
    run(args)
  }
}

class BloopProcessor extends Processor {
  override def processRequest(args: util.List[String]): Unit = {
    var argsArrayBuffer = scala.collection.mutable.ArrayBuffer[String]()
    for (i <- 0 to args.size-1) {
      argsArrayBuffer += args.get(i)
    }

    println("HELLO")

    val parser = ArgumentParsers.newFor("scalafmt").addHelp(true).defaultFormatWidth(80).fromFilePrefix("@").build
    parser.addArgument("--someFile").required(true).`type`(Arguments.fileType)

    val namespace = parser.parseArgsOrFail(argsArrayBuffer.toArray)

    val source = namespace.get[File]("--someFile")
    println(source)

  }
}