load(
    "//scala:scala_cross_version.bzl",
    _default_scala_version = "default_scala_version",
    _extract_major_version = "extract_major_version",
    _scala_mvn_artifact = "scala_mvn_artifact",
)
load(
    "@io_bazel_rules_scala//scala:scala_maven_import_external.bzl",
    _scala_maven_import_external = "scala_maven_import_external",
)


def bloop_repositories(
        scala_version = _default_scala_version(),
        maven_servers = ["http://central.maven.org/maven2"]):
    major_version = _extract_major_version(scala_version)


    _scala_maven_import_external(
        name = "argparse4j",
        artifact = "net.sourceforge.argparse4j:argparse4j:0.8.1",
        artifact_sha256 = "98cb5468cac609f3bc07856f2e34088f50dc114181237c48d20ca69c3265d044",
        licenses = ["notice"],
        server_urls = maven_servers,
    )

    native.bind(
        name = "io_bazel_rules_scala/scalafmt/argparse4j",
        actual = "@argparse4j",
    )


    _scala_maven_import_external(
        name = "bsp4j",
        artifact = "ch.epfl.scala:bsp4j:2.0.0-M4+10-61e61e87",
        licenses = ["notice"],
        server_urls = maven_servers,
    )

    native.bind(
        name = "io_bazel_rules_scala/bloop/bsp4j",
        actual = "@bsp4j",
    )

    _scala_maven_import_external(
        name = "lsp4j-jsonrpc",
        artifact = "org.eclipse.lsp4j:org.eclipse.lsp4j.jsonrpc:0.5.0",
        licenses = ["notice"],
        server_urls = maven_servers,
    )

    native.bind(
        name = "io_bazel_rules_scala/bloop/lsp4j-jsonrpc",
        actual = "@lsp4j-jsonrpc",
    )


    _scala_maven_import_external(
        name = "bloop-config",
        artifact = "ch.epfl.scala:bloop-config_2.12:1.2.5",
        licenses = ["notice"],
        server_urls = maven_servers,
    )

    native.bind(
        name = "io_bazel_rules_scala/bloop/bloopconfig",
        actual = "@bloop-config",
    )

    _scala_maven_import_external(
        name = "bloop-launcher",
        artifact = "ch.epfl.scala:bloop-launcher_2.12:1.2.5",
        licenses = ["notice"],
        server_urls = maven_servers,
    )

    native.bind(
        name = "io_bazel_rules_scala/bloop/blooplauncher",
        actual = "@bloop-launcher",
    )


    _scala_maven_import_external(
        name = "java8-compat",
        artifact = "org.scala-lang.modules:scala-java8-compat_2.12:0.8.0",
        licenses = ["notice"],
        server_urls = maven_servers,
    )

    native.bind(
        name = "io_bazel_rules_scala/scala_lang/java8-compat",
        actual = "@java8-compat",
    )

    _scala_maven_import_external(
        name = "ipcsocket",
        artifact = "org.scala-sbt.ipcsocket:ipcsocket:1.0.0",
        licenses = ["notice"],
        server_urls = maven_servers,
    )

    native.bind(
        name = "io_bazel_rules_scala/sbt/ipcsocket",
        actual = "@ipcsocket",
    )