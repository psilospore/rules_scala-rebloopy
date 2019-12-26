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
        "@scalafmt//:net_sourceforge_argparse4j_argparse4j", #TODO move
        "//external:io_bazel_rules_scala/bloop/bsp4j",
        "//external:io_bazel_rules_scala/bloop/bloopconfig",
        "//external:io_bazel_rules_scala/bloop/blooplauncher",
        "//external:io_bazel_rules_scala/bloop/lsp4j-jsonrpc",


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
