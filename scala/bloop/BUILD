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
    #TODO for other scala versions I might have to specify dependencies for jline or scala_xml
    deps = [
        "//external:io_bazel_rules_scala/dependency/scala/scala_compiler",
        "//external:io_bazel_rules_scala/dependency/scala/scala_reflect",
        "//external:io_bazel_rules_scala/dependency/scala/scala_library",
        "//src/java/io/bazel/rulesscala/worker",
        "//3rdparty/jvm/net/sourceforge/argparse4j:argparse4j",
        "//3rdparty/jvm/ch/epfl/scala:bsp4j",
        "//3rdparty/jvm/ch/epfl/scala:bloop_config",
        "//3rdparty/jvm/ch/epfl/scala:bloop_launcher",
        "//3rdparty/jvm/org/scala_lang/modules:scala_java8_compat",
        "//src/java/io/bazel/rulesscala/jar",
        "//3rdparty/jvm/commons_io:commons_io",
    ],
    unused_dependency_checker_mode = "warn", #TODO I'm using the scala compiler libs but from the classpath
)

load(
    "//scala/bloop:ext.bzl",
    _add_phase_bloop_singleton = "add_phase_bloop_singleton",
)

_add_phase_bloop_singleton(
    name = "add_phase_bloop",
    visibility = ["//visibility:public"],
)
