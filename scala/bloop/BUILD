load("//scala:scala.bzl", "scala_binary")

#filegroup(
#    name = "runner",
#    srcs = ["private/format.template.sh"],
#    visibility = ["//visibility:public"],
#)

# Think this could be used when I'm locally developing?
#filegroup(
#    name = "testrunner",
#    srcs = ["private/format-test.template.sh"],
#    visibility = ["//visibility:public"],
#)

scala_binary(
    name = "bloop",
    srcs = glob(["bloop/BloopRunner.scala"]),
    main_class = "io.bazel.rules_scala.bloop.BloopRunner",
    visibility = ["//visibility:public"],
    deps = [
        "//src/java/io/bazel/rulesscala/worker",
        "//3rdparty/jvm/net/sourceforge/argparse4j:argparse4j",
        "//3rdparty/jvm/ch/epfl/scala:bsp4j",
        "//3rdparty/jvm/ch/epfl/scala:bloop_config",
        "//3rdparty/jvm/ch/epfl/scala:bloop_launcher",
        "//3rdparty/jvm/org/scala_lang/modules:scala_java8_compat",

#        "//external:io_bazel_rules_scala/bloop/lsp4j-jsonrpc", # why do I need this
#        "//external:io_bazel_rules_scala/sbt/ipcsocket", # ok somethings wrong
#        "//external:io_bazel_rules_scala/scala_lang/java8-compat",
    ],
    unused_dependency_checker_mode = "warn", #TODO

)

load(
    "//scala/bloop:ext.bzl",
    _add_phase_bloop_singleton = "add_phase_bloop_singleton",
)

_add_phase_bloop_singleton(
    name = "add_phase_bloop",
    visibility = ["//visibility:public"],
)
