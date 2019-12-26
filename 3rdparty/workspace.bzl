# Do not edit. bazel-deps autogenerates this file from dependencies.yaml.
def _jar_artifact_impl(ctx):
    jar_name = "%s.jar" % ctx.name
    ctx.download(
        output=ctx.path("jar/%s" % jar_name),
        url=ctx.attr.urls,
        sha256=ctx.attr.sha256,
        executable=False
    )
    src_name="%s-sources.jar" % ctx.name
    srcjar_attr=""
    has_sources = len(ctx.attr.src_urls) != 0
    if has_sources:
        ctx.download(
            output=ctx.path("jar/%s" % src_name),
            url=ctx.attr.src_urls,
            sha256=ctx.attr.src_sha256,
            executable=False
        )
        srcjar_attr ='\n    srcjar = ":%s",' % src_name

    build_file_contents = """
package(default_visibility = ['//visibility:public'])
java_import(
    name = 'jar',
    tags = ['maven_coordinates={artifact}'],
    jars = ['{jar_name}'],{srcjar_attr}
)
filegroup(
    name = 'file',
    srcs = [
        '{jar_name}',
        '{src_name}'
    ],
    visibility = ['//visibility:public']
)\n""".format(artifact = ctx.attr.artifact, jar_name = jar_name, src_name = src_name, srcjar_attr = srcjar_attr)
    ctx.file(ctx.path("jar/BUILD"), build_file_contents, False)
    return None

jar_artifact = repository_rule(
    attrs = {
        "artifact": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "urls": attr.string_list(mandatory = True),
        "src_sha256": attr.string(mandatory = False, default=""),
        "src_urls": attr.string_list(mandatory = False, default=[]),
    },
    implementation = _jar_artifact_impl
)

def jar_artifact_callback(hash):
    src_urls = []
    src_sha256 = ""
    source=hash.get("source", None)
    if source != None:
        src_urls = [source["url"]]
        src_sha256 = source["sha256"]
    jar_artifact(
        artifact = hash["artifact"],
        name = hash["name"],
        urls = [hash["url"]],
        sha256 = hash["sha256"],
        src_urls = src_urls,
        src_sha256 = src_sha256
    )
    native.bind(name = hash["bind"], actual = hash["actual"])


def list_dependencies():
    return [
    {"artifact": "ch.epfl.scala:bloop-config_2.12:1.2.5", "lang": "scala", "sha1": "c9d19747155687ba85d382758156b87ac56f5259", "sha256": "55eff49af1a8ff8e2d813508b5d6dd45de80e09dab2f0ae3658fc6981640c486", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/ch/epfl/scala/bloop-config_2.12/1.2.5/bloop-config_2.12-1.2.5.jar", "source": {"sha1": "81350d3416e5d002cb2b3f41259a257410700d33", "sha256": "91ac320bbc6bdb3b1fe5012b51ab143a566ef71af2bda8ad0c78de272f13a813", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/ch/epfl/scala/bloop-config_2.12/1.2.5/bloop-config_2.12-1.2.5-sources.jar"} , "name": "ch_epfl_scala_bloop_config_2_12", "actual": "@ch_epfl_scala_bloop_config_2_12//jar:file", "bind": "jar/ch/epfl/scala/bloop_config_2_12"},
    {"artifact": "ch.epfl.scala:bloop-launcher_2.12:1.4.0-RC1", "lang": "scala", "sha1": "3e7f1f877d9f0aa5afcbfc3e6b0deac1b39bea70", "sha256": "7cb4b697bdf96c328592575e1c717169a931a27e546b6d601e7bc5900b9d69c5", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/ch/epfl/scala/bloop-launcher_2.12/1.4.0-RC1/bloop-launcher_2.12-1.4.0-RC1.jar", "source": {"sha1": "c281d59a5ad06fd874dfa117fb623e23bd9ceb35", "sha256": "9cab4e71803a1b5ef45a20a52c8e3e4f74f1fa3d908396639381131e33f6e44b", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/ch/epfl/scala/bloop-launcher_2.12/1.4.0-RC1/bloop-launcher_2.12-1.4.0-RC1-sources.jar"} , "name": "ch_epfl_scala_bloop_launcher_2_12", "actual": "@ch_epfl_scala_bloop_launcher_2_12//jar:file", "bind": "jar/ch/epfl/scala/bloop_launcher_2_12"},
    {"artifact": "ch.epfl.scala:bsp4j:2.0.0-M4+10-61e61e87", "lang": "java", "sha1": "808fde06b67c46740f2691ea4783061f8de84079", "sha256": "2097d1e0809162def490519d8965f6ce61c49649430fc79798a49c1072155445", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/ch/epfl/scala/bsp4j/2.0.0-M4+10-61e61e87/bsp4j-2.0.0-M4+10-61e61e87.jar", "source": {"sha1": "8dac6750aa1c7951a4229f29ca6138440490e398", "sha256": "b1d6a94a168d70962f9fec6f89ba88201f436ca929e605eef50fd1d21e6d51c7", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/ch/epfl/scala/bsp4j/2.0.0-M4+10-61e61e87/bsp4j-2.0.0-M4+10-61e61e87-sources.jar"} , "name": "ch_epfl_scala_bsp4j", "actual": "@ch_epfl_scala_bsp4j//jar", "bind": "jar/ch/epfl/scala/bsp4j"},
    {"artifact": "com.chuusai:shapeless_2.12:2.3.3", "lang": "java", "sha1": "6041e2c4871650c556a9c6842e43c04ed462b11f", "sha256": "312e301432375132ab49592bd8d22b9cd42a338a6300c6157fb4eafd1e3d5033", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/chuusai/shapeless_2.12/2.3.3/shapeless_2.12-2.3.3.jar", "source": {"sha1": "02511271188a92962fcf31a9a217b8122f75453a", "sha256": "2d53fea1b1ab224a4a731d99245747a640deaa6ef3912c253666aa61287f3d63", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/chuusai/shapeless_2.12/2.3.3/shapeless_2.12-2.3.3-sources.jar"} , "name": "com_chuusai_shapeless_2_12", "actual": "@com_chuusai_shapeless_2_12//jar", "bind": "jar/com/chuusai/shapeless_2_12"},
    {"artifact": "com.github.alexarchambault:argonaut-shapeless_6.2_2.12:1.2.0-M10", "lang": "java", "sha1": "20ff892fa9f74e58045ec9d0ce49b20805dee7f0", "sha256": "70a998f56671ea1ab6eb1c9390e116ecc71c487e2b7a773a6e903736666a4137", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/github/alexarchambault/argonaut-shapeless_6.2_2.12/1.2.0-M10/argonaut-shapeless_6.2_2.12-1.2.0-M10.jar", "source": {"sha1": "cbd38728b8757ee41d115a3599713eb8954f6455", "sha256": "3d1bda52c7686c611a79d3ee09f5a80e6dad303e4465ab63e5ca5243e92b944c", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/github/alexarchambault/argonaut-shapeless_6.2_2.12/1.2.0-M10/argonaut-shapeless_6.2_2.12-1.2.0-M10-sources.jar"} , "name": "com_github_alexarchambault_argonaut_shapeless_6_2_2_12", "actual": "@com_github_alexarchambault_argonaut_shapeless_6_2_2_12//jar", "bind": "jar/com/github/alexarchambault/argonaut_shapeless_6_2_2_12"},
    {"artifact": "com.google.code.findbugs:jsr305:3.0.2", "lang": "java", "sha1": "25ea2e8b0c338a877313bd4672d3fe056ea78f0d", "sha256": "766ad2a0783f2687962c8ad74ceecc38a28b9f72a2d085ee438b7813e928d0c7", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2.jar", "source": {"sha1": "b19b5927c2c25b6c70f093767041e641ae0b1b35", "sha256": "1c9e85e272d0708c6a591dc74828c71603053b48cc75ae83cce56912a2aa063b", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2-sources.jar"} , "name": "com_google_code_findbugs_jsr305", "actual": "@com_google_code_findbugs_jsr305//jar", "bind": "jar/com/google/code/findbugs/jsr305"},
    {"artifact": "com.google.code.gson:gson:2.7", "lang": "java", "sha1": "751f548c85fa49f330cecbb1875893f971b33c4e", "sha256": "2d43eb5ea9e133d2ee2405cc14f5ee08951b8361302fdd93494a3a997b508d32", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/code/gson/gson/2.7/gson-2.7.jar", "source": {"sha1": "bbb63ca253b483da8ee53a50374593923e3de2e2", "sha256": "2d3220d5d936f0a26258aa3b358160741a4557e046a001251e5799c2db0f0d74", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/code/gson/gson/2.7/gson-2.7-sources.jar"} , "name": "com_google_code_gson_gson", "actual": "@com_google_code_gson_gson//jar", "bind": "jar/com/google/code/gson/gson"},
    {"artifact": "com.google.errorprone:error_prone_annotations:2.2.0", "lang": "java", "sha1": "88e3c593e9b3586e1c6177f89267da6fc6986f0c", "sha256": "6ebd22ca1b9d8ec06d41de8d64e0596981d9607b42035f9ed374f9de271a481a", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/errorprone/error_prone_annotations/2.2.0/error_prone_annotations-2.2.0.jar", "source": {"sha1": "a8cd7823aa1dcd2fd6677c0c5988fdde9d1fb0a3", "sha256": "626adccd4894bee72c3f9a0384812240dcc1282fb37a87a3f6cb94924a089496", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/errorprone/error_prone_annotations/2.2.0/error_prone_annotations-2.2.0-sources.jar"} , "name": "com_google_errorprone_error_prone_annotations", "actual": "@com_google_errorprone_error_prone_annotations//jar", "bind": "jar/com/google/errorprone/error_prone_annotations"},
    {"artifact": "com.google.guava:failureaccess:1.0.1", "lang": "java", "sha1": "1dcf1de382a0bf95a3d8b0849546c88bac1292c9", "sha256": "a171ee4c734dd2da837e4b16be9df4661afab72a41adaf31eb84dfdaf936ca26", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar", "source": {"sha1": "1d064e61aad6c51cc77f9b59dc2cccc78e792f5a", "sha256": "092346eebbb1657b51aa7485a246bf602bb464cc0b0e2e1c7e7201fadce1e98f", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1-sources.jar"} , "name": "com_google_guava_failureaccess", "actual": "@com_google_guava_failureaccess//jar", "bind": "jar/com/google/guava/failureaccess"},
    {"artifact": "com.google.guava:guava:27.1-jre", "lang": "java", "sha1": "e47b59c893079b87743cdcfb6f17ca95c08c592c", "sha256": "4a5aa70cc968a4d137e599ad37553e5cfeed2265e8c193476d7119036c536fe7", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/guava/guava/27.1-jre/guava-27.1-jre.jar", "source": {"sha1": "5dfa313690a903560bf27478345780a607bf1e9b", "sha256": "9de05c573971cedfcd53fb85fc7a58a5f453053026a9bf18594cffc79a1d6874", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/guava/guava/27.1-jre/guava-27.1-jre-sources.jar"} , "name": "com_google_guava_guava", "actual": "@com_google_guava_guava//jar", "bind": "jar/com/google/guava/guava"},
    {"artifact": "com.google.guava:listenablefuture:9999.0-empty-to-avoid-conflict-with-guava", "lang": "java", "sha1": "b421526c5f297295adef1c886e5246c39d4ac629", "sha256": "b372a037d4230aa57fbeffdef30fd6123f9c0c2db85d0aced00c91b974f33f99", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/guava/listenablefuture/9999.0-empty-to-avoid-conflict-with-guava/listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.jar", "name": "com_google_guava_listenablefuture", "actual": "@com_google_guava_listenablefuture//jar", "bind": "jar/com/google/guava/listenablefuture"},
    {"artifact": "com.google.j2objc:j2objc-annotations:1.1", "lang": "java", "sha1": "ed28ded51a8b1c6b112568def5f4b455e6809019", "sha256": "2994a7eb78f2710bd3d3bfb639b2c94e219cedac0d4d084d516e78c16dddecf6", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/j2objc/j2objc-annotations/1.1/j2objc-annotations-1.1.jar", "source": {"sha1": "1efdf5b737b02f9b72ebdec4f72c37ec411302ff", "sha256": "2cd9022a77151d0b574887635cdfcdf3b78155b602abc89d7f8e62aba55cfb4f", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/com/google/j2objc/j2objc-annotations/1.1/j2objc-annotations-1.1-sources.jar"} , "name": "com_google_j2objc_j2objc_annotations", "actual": "@com_google_j2objc_j2objc_annotations//jar", "bind": "jar/com/google/j2objc/j2objc_annotations"},
    {"artifact": "commons-io:commons-io:2.0.1", "lang": "java", "sha1": "7ffdb02f95af1c1a208544e076cea5b8e66e731a", "sha256": "2a3f5a206480863aae9dff03f53c930c3add6912f8785498d59442c7ebb98c5c", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/commons-io/commons-io/2.0.1/commons-io-2.0.1.jar", "source": {"sha1": "8ace0a355c375f0d20d04fa0db7b986c6637a689", "sha256": "9efca5493dca44111bd71c6a8b8d902ee9a097cbc346bc8b98c1c140c94ebfc9", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/commons-io/commons-io/2.0.1/commons-io-2.0.1-sources.jar"} , "name": "commons_io_commons_io", "actual": "@commons_io_commons_io//jar", "bind": "jar/commons_io/commons_io"},
    {"artifact": "io.argonaut:argonaut_2.12:6.2.3", "lang": "java", "sha1": "69a6b591af7b2043bb69e38bbdbd025c62730d0c", "sha256": "61166b8ae9490e603074f93362598358b603444615c7e094fd822ba114db548b", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/argonaut/argonaut_2.12/6.2.3/argonaut_2.12-6.2.3.jar", "source": {"sha1": "5b42488698da54da924c955621e0d603603070f7", "sha256": "0cc0e3c4839d59658936fd383aebcb0e1bf2be0f7e820545a873b3c6597b9eb2", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/argonaut/argonaut_2.12/6.2.3/argonaut_2.12-6.2.3-sources.jar"} , "name": "io_argonaut_argonaut_2_12", "actual": "@io_argonaut_argonaut_2_12//jar", "bind": "jar/io/argonaut/argonaut_2_12"},
    {"artifact": "io.circe:circe-core_2.12:0.9.3", "lang": "java", "sha1": "f4f8674788f571d840ed98fabf3237f72c86d1f0", "sha256": "256527a2ce81b91db1d3cc27f44dc920a8cb33ff32c1d6e6d9813799df774e20", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/circe/circe-core_2.12/0.9.3/circe-core_2.12-0.9.3.jar", "source": {"sha1": "e8d75320f4b9ea89cae59129c4acd2f328b161bb", "sha256": "a84c0f7651d1a1ef2c4fb7df802965b572680f88e6128f09f137be19759e9e78", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/circe/circe-core_2.12/0.9.3/circe-core_2.12-0.9.3-sources.jar"} , "name": "io_circe_circe_core_2_12", "actual": "@io_circe_circe_core_2_12//jar", "bind": "jar/io/circe/circe_core_2_12"},
    {"artifact": "io.circe:circe-derivation_2.12:0.9.0-M3", "lang": "java", "sha1": "6285eb999ba193a8b7a0eb361dc38de803a19074", "sha256": "055edaacc4f4b4e8e3c49523b23cb313a24f11db64d7ab7bd210e14c6fc5d89f", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/circe/circe-derivation_2.12/0.9.0-M3/circe-derivation_2.12-0.9.0-M3.jar", "source": {"sha1": "13bbd66539f932c3a71506c3dd6a6b5818e6cdc2", "sha256": "a144bf1b9ab92965db68d53f4020c001961989a79f98e05db47fdfd8afc1061b", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/circe/circe-derivation_2.12/0.9.0-M3/circe-derivation_2.12-0.9.0-M3-sources.jar"} , "name": "io_circe_circe_derivation_2_12", "actual": "@io_circe_circe_derivation_2_12//jar", "bind": "jar/io/circe/circe_derivation_2_12"},
    {"artifact": "io.circe:circe-jawn_2.12:0.9.3", "lang": "java", "sha1": "8462d202404f578f09cc9b89d7dca57dd94b09e5", "sha256": "0f3b99235b0180482a1a00dcfc2fe7604a42c027923dc4c1b5e99f7ffc507d9d", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/circe/circe-jawn_2.12/0.9.3/circe-jawn_2.12-0.9.3.jar", "source": {"sha1": "950197dda0fbe37b216a7d11e3be4b4b8861ef52", "sha256": "a2f0e0fb26bb000426af13fa0e6389642f06feb9f1b4e9620aa8c6e584ccdfd8", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/circe/circe-jawn_2.12/0.9.3/circe-jawn_2.12-0.9.3-sources.jar"} , "name": "io_circe_circe_jawn_2_12", "actual": "@io_circe_circe_jawn_2_12//jar", "bind": "jar/io/circe/circe_jawn_2_12"},
    {"artifact": "io.circe:circe-numbers_2.12:0.9.3", "lang": "java", "sha1": "e8b931a2a2438d9ba84ff5ecbfb2a4ac7249b0d8", "sha256": "49cd74886f74659b239b6a85f3ba8e24f212a9e6b299fb9a793e092905bc8fa3", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/circe/circe-numbers_2.12/0.9.3/circe-numbers_2.12-0.9.3.jar", "source": {"sha1": "dadf859faeee2572b50cf9f5e4cbe0d5dd0f29e0", "sha256": "562f7bc8dab9917b5e903cd8931a52cfce22d6a2fa53df1919ad5088580b8eb2", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/circe/circe-numbers_2.12/0.9.3/circe-numbers_2.12-0.9.3-sources.jar"} , "name": "io_circe_circe_numbers_2_12", "actual": "@io_circe_circe_numbers_2_12//jar", "bind": "jar/io/circe/circe_numbers_2_12"},
    {"artifact": "io.circe:circe-parser_2.12:0.9.3", "lang": "java", "sha1": "9af9ad5e8a2027a7d93a2b21578f727f73f55d79", "sha256": "35613794c8881186487beaf5a620cd0f6f128cffd4e7a2c777ef034cb4bd1f75", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/circe/circe-parser_2.12/0.9.3/circe-parser_2.12-0.9.3.jar", "source": {"sha1": "0b0ee1069326c38ca7c0ced5c2b1337774c72876", "sha256": "08e1cdf76c77951b8771f2485756f6e9137de6473bfbaaabd86c9f568827b0a1", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/circe/circe-parser_2.12/0.9.3/circe-parser_2.12-0.9.3-sources.jar"} , "name": "io_circe_circe_parser_2_12", "actual": "@io_circe_circe_parser_2_12//jar", "bind": "jar/io/circe/circe_parser_2_12"},
    {"artifact": "io.get-coursier:coursier-cache_2.12:1.1.0-M14", "lang": "java", "sha1": "4684f39353764bebf17e6f854e1fb9be4a3aaa6e", "sha256": "9b540a035056d7f902b528adc1c54c125e40c7aea386e71a362c277dea5db8a0", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/get-coursier/coursier-cache_2.12/1.1.0-M14/coursier-cache_2.12-1.1.0-M14.jar", "source": {"sha1": "d55d53d8e1336bfdc08f1abc1a785f38cf952f70", "sha256": "3cd41eb600d2d633dcfc2014ad934e82a614b494475dca5f16667b85103800f3", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/get-coursier/coursier-cache_2.12/1.1.0-M14/coursier-cache_2.12-1.1.0-M14-sources.jar"} , "name": "io_get_coursier_coursier_cache_2_12", "actual": "@io_get_coursier_coursier_cache_2_12//jar", "bind": "jar/io/get_coursier/coursier_cache_2_12"},
    {"artifact": "io.get-coursier:coursier-core_2.12:1.1.0-M14", "lang": "java", "sha1": "4f304a2a5c932500e1a30d329220154c3b78594c", "sha256": "1f15f23eddf633e6915a091d0f60fee1b25a928c6e8315a381b634afaa98a332", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/get-coursier/coursier-core_2.12/1.1.0-M14/coursier-core_2.12-1.1.0-M14.jar", "source": {"sha1": "44e44b05fbc62093ef6c802f58d3ad1bbb027378", "sha256": "ca6dac3fad7fb68d8ac9468a09023e052c451609ad82531c283fc2244b252093", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/get-coursier/coursier-core_2.12/1.1.0-M14/coursier-core_2.12-1.1.0-M14-sources.jar"} , "name": "io_get_coursier_coursier_core_2_12", "actual": "@io_get_coursier_coursier_core_2_12//jar", "bind": "jar/io/get_coursier/coursier_core_2_12"},
    {"artifact": "io.get-coursier:coursier_2.12:1.1.0-M14", "lang": "scala", "sha1": "7cb9c5e0c58ea411ef2dd49974c00479156e97c1", "sha256": "6cd54cca6f3125efbd5cfe942b2bf6d14332afadc65cffcb6f299b4ac6bdda38", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/get-coursier/coursier_2.12/1.1.0-M14/coursier_2.12-1.1.0-M14.jar", "source": {"sha1": "d224dcdc76c3377e90c74553146dffe5f45ada71", "sha256": "8199afef2d2e183c9bdc33b2d7707a04fa51c62c5d5eb18d28586d564909cd90", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/io/get-coursier/coursier_2.12/1.1.0-M14/coursier_2.12-1.1.0-M14-sources.jar"} , "name": "io_get_coursier_coursier_2_12", "actual": "@io_get_coursier_coursier_2_12//jar:file", "bind": "jar/io/get_coursier/coursier_2_12"},
    {"artifact": "net.java.dev.jna:jna-platform:4.5.0", "lang": "java", "sha1": "00ab163522ed76eb01c8c9a750dedacb134fc8c0", "sha256": "68ee6431c6c07dda48deaa2627c56beeea0dec5927fe7848983e06f7a6a76a08", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/net/java/dev/jna/jna-platform/4.5.0/jna-platform-4.5.0.jar", "source": {"sha1": "b1557051d9a8cfdd24e1e5d99304be2d7b515d93", "sha256": "c0d41cc08b93646f90495bf850105dc9af1116169868b93589366c689eb5ddee", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/net/java/dev/jna/jna-platform/4.5.0/jna-platform-4.5.0-sources.jar"} , "name": "net_java_dev_jna_jna_platform", "actual": "@net_java_dev_jna_jna_platform//jar", "bind": "jar/net/java/dev/jna/jna_platform"},
    {"artifact": "net.java.dev.jna:jna:4.5.0", "lang": "java", "sha1": "55b548d3195efc5280bf1c3f17b49659c54dee40", "sha256": "617a8d75f66a57296255a13654a99f10f72f0964336e352211247ed046da3e94", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/net/java/dev/jna/jna/4.5.0/jna-4.5.0.jar", "source": {"sha1": "81072e8420f1635a3625cdfd253ccea6e33535cc", "sha256": "e4da62978d75a5f47641d6c3548a6859c193fad8c5d0bc95a5f049d8ec1a0f79", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/net/java/dev/jna/jna/4.5.0/jna-4.5.0-sources.jar"} , "name": "net_java_dev_jna_jna", "actual": "@net_java_dev_jna_jna//jar", "bind": "jar/net/java/dev/jna/jna"},
    {"artifact": "net.sourceforge.argparse4j:argparse4j:0.8.1", "lang": "java", "sha1": "2c8241f84acf6c924bd75be0dbd68e8d74fbcd70", "sha256": "98cb5468cac609f3bc07856f2e34088f50dc114181237c48d20ca69c3265d044", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/net/sourceforge/argparse4j/argparse4j/0.8.1/argparse4j-0.8.1.jar", "source": {"sha1": "779289966bb88f72751923bf2990ddde7f7a6507", "sha256": "6baf8893d69bf3b8cac582de8b6407ebfeac992b1694b11897a9a614fb4b892f", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/net/sourceforge/argparse4j/argparse4j/0.8.1/argparse4j-0.8.1-sources.jar"} , "name": "net_sourceforge_argparse4j_argparse4j", "actual": "@net_sourceforge_argparse4j_argparse4j//jar", "bind": "jar/net/sourceforge/argparse4j/argparse4j"},
    {"artifact": "org.checkerframework:checker-qual:2.5.2", "lang": "java", "sha1": "cea74543d5904a30861a61b4643a5f2bb372efc4", "sha256": "64b02691c8b9d4e7700f8ee2e742dce7ea2c6e81e662b7522c9ee3bf568c040a", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/checkerframework/checker-qual/2.5.2/checker-qual-2.5.2.jar", "source": {"sha1": "ebb8ebccd42218434674f3e1d9022c13df1c19f8", "sha256": "821c5c63a6f156a3bb498c5bbb613580d9d8f4134131a5627d330fc4018669d2", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/checkerframework/checker-qual/2.5.2/checker-qual-2.5.2-sources.jar"} , "name": "org_checkerframework_checker_qual", "actual": "@org_checkerframework_checker_qual//jar", "bind": "jar/org/checkerframework/checker_qual"},
    {"artifact": "org.codehaus.mojo:animal-sniffer-annotations:1.17", "lang": "java", "sha1": "f97ce6decaea32b36101e37979f8b647f00681fb", "sha256": "92654f493ecfec52082e76354f0ebf87648dc3d5cec2e3c3cdb947c016747a53", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/codehaus/mojo/animal-sniffer-annotations/1.17/animal-sniffer-annotations-1.17.jar", "source": {"sha1": "8fb5b5ad9c9723951b9fccaba5bb657fa6064868", "sha256": "2571474a676f775a8cdd15fb9b1da20c4c121ed7f42a5d93fca0e7b6e2015b40", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/codehaus/mojo/animal-sniffer-annotations/1.17/animal-sniffer-annotations-1.17-sources.jar"} , "name": "org_codehaus_mojo_animal_sniffer_annotations", "actual": "@org_codehaus_mojo_animal_sniffer_annotations//jar", "bind": "jar/org/codehaus/mojo/animal_sniffer_annotations"},
    {"artifact": "org.eclipse.lsp4j:org.eclipse.lsp4j.generator:0.5.0", "lang": "java", "sha1": "23800c88ee887571b43a4f08041922107843e506", "sha256": "16969a1950d67d42b1206f2acfc17e0ea2bc49410bbba9ee420b507a39b7f314", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/eclipse/lsp4j/org.eclipse.lsp4j.generator/0.5.0/org.eclipse.lsp4j.generator-0.5.0.jar", "source": {"sha1": "3ecac419332e44f4e3a5299f1b604721b1f1442b", "sha256": "d7f122f5e9c3305cb03e2a8b3422cb852e55b8aaa6057927f9f0109fe0b57751", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/eclipse/lsp4j/org.eclipse.lsp4j.generator/0.5.0/org.eclipse.lsp4j.generator-0.5.0-sources.jar"} , "name": "org_eclipse_lsp4j_org_eclipse_lsp4j_generator", "actual": "@org_eclipse_lsp4j_org_eclipse_lsp4j_generator//jar", "bind": "jar/org/eclipse/lsp4j/org_eclipse_lsp4j_generator"},
    {"artifact": "org.eclipse.lsp4j:org.eclipse.lsp4j.jsonrpc:0.5.0", "lang": "java", "sha1": "4fe4e91d47494b73ded7e420806661f7c36a1b05", "sha256": "0ab206ff110913bb5bddbbc29a3ffdebeb4394d9fa449053da98682dfdfe5578", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/eclipse/lsp4j/org.eclipse.lsp4j.jsonrpc/0.5.0/org.eclipse.lsp4j.jsonrpc-0.5.0.jar", "source": {"sha1": "49aeb3132eeef5d8aedb195d37c81a8efa656b54", "sha256": "1e6450932c88ef769c5f6cdd2e24b52c8f56c119bb1ad9635a71a08ceabbf992", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/eclipse/lsp4j/org.eclipse.lsp4j.jsonrpc/0.5.0/org.eclipse.lsp4j.jsonrpc-0.5.0-sources.jar"} , "name": "org_eclipse_lsp4j_org_eclipse_lsp4j_jsonrpc", "actual": "@org_eclipse_lsp4j_org_eclipse_lsp4j_jsonrpc//jar", "bind": "jar/org/eclipse/lsp4j/org_eclipse_lsp4j_jsonrpc"},
    {"artifact": "org.eclipse.xtend:org.eclipse.xtend.lib.macro:2.20.0", "lang": "java", "sha1": "04e429d55748e09021ded1e6e78515e736159ffd", "sha256": "ac38cd933967146dfd8ad9f9e08b1091dd16a0192486ca8c6b1bb8e12c3e7d85", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/eclipse/xtend/org.eclipse.xtend.lib.macro/2.20.0/org.eclipse.xtend.lib.macro-2.20.0.jar", "source": {"sha1": "4abda528d9e3b17c293aa75105f05b05a4a56b69", "sha256": "03d14864d16179602f2d5b8d8bf1206f95d984b47c7edf85c6467dab8641e6eb", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/eclipse/xtend/org.eclipse.xtend.lib.macro/2.20.0/org.eclipse.xtend.lib.macro-2.20.0-sources.jar"} , "name": "org_eclipse_xtend_org_eclipse_xtend_lib_macro", "actual": "@org_eclipse_xtend_org_eclipse_xtend_lib_macro//jar", "bind": "jar/org/eclipse/xtend/org_eclipse_xtend_lib_macro"},
    {"artifact": "org.eclipse.xtend:org.eclipse.xtend.lib:[2.11.0,3)", "lang": "java", "sha1": "f2b4d75879e699f5e464f5c00586da03def877ca", "sha256": "937bf9bdee5c63714d7a793e47058c86d926f6df1424bc352bd21eefac1663c2", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/eclipse/xtend/org.eclipse.xtend.lib/2.20.0/org.eclipse.xtend.lib-2.20.0.jar", "source": {"sha1": "855a7ecf80d6d758f9e10a6ffafd74ac1fcafa5e", "sha256": "7e839e19bd26b9834edff59a9b3d352777b7d833d33b07de50f9e84fab84f71c", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/eclipse/xtend/org.eclipse.xtend.lib/2.20.0/org.eclipse.xtend.lib-2.20.0-sources.jar"} , "name": "org_eclipse_xtend_org_eclipse_xtend_lib", "actual": "@org_eclipse_xtend_org_eclipse_xtend_lib//jar", "bind": "jar/org/eclipse/xtend/org_eclipse_xtend_lib"},
    {"artifact": "org.eclipse.xtext:org.eclipse.xtext.xbase.lib:2.20.0", "lang": "java", "sha1": "55e9d0630f0f64735d0b564cdbee0b1f2217bceb", "sha256": "51719f38219992ea8218e18e0e76e19b0b099516fbca517361d17751c0090194", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/eclipse/xtext/org.eclipse.xtext.xbase.lib/2.20.0/org.eclipse.xtext.xbase.lib-2.20.0.jar", "source": {"sha1": "0affcf538a893a6637377ad9985866bba8fa7e7e", "sha256": "3e08c20e2bf5a7e61002c92b6eb5eb26fe91bca0d55ac292904ade06865b8614", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/eclipse/xtext/org.eclipse.xtext.xbase.lib/2.20.0/org.eclipse.xtext.xbase.lib-2.20.0-sources.jar"} , "name": "org_eclipse_xtext_org_eclipse_xtext_xbase_lib", "actual": "@org_eclipse_xtext_org_eclipse_xtext_xbase_lib//jar", "bind": "jar/org/eclipse/xtext/org_eclipse_xtext_xbase_lib"},
    {"artifact": "org.scala-lang.modules:scala-java8-compat_2.12:0.8.0", "lang": "scala", "sha1": "1e6f1e745bf6d3c34d1e2ab150653306069aaf34", "sha256": "d9d5dfd1bc49a8158e6e0a90b2ed08fa602984d815c00af16cec53557e83ef8e", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/scala-lang/modules/scala-java8-compat_2.12/0.8.0/scala-java8-compat_2.12-0.8.0.jar", "source": {"sha1": "0a33ce48278b9e3bbea8aed726e3c0abad3afadd", "sha256": "c0926003987a5c21108748fda401023485085eaa9fe90a41a40bcf67596fff34", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/scala-lang/modules/scala-java8-compat_2.12/0.8.0/scala-java8-compat_2.12-0.8.0-sources.jar"} , "name": "org_scala_lang_modules_scala_java8_compat_2_12", "actual": "@org_scala_lang_modules_scala_java8_compat_2_12//jar:file", "bind": "jar/org/scala_lang/modules/scala_java8_compat_2_12"},
    {"artifact": "org.scala-lang.modules:scala-xml_2.12:1.1.1", "lang": "java", "sha1": "f56ecaf2e5b7138c87449303c763fd1654543fde", "sha256": "dbc3964556e8ac9de5378fc0f8c5f657cd8e1f9896a0d005f4f469c6b056f9be", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/scala-lang/modules/scala-xml_2.12/1.1.1/scala-xml_2.12-1.1.1.jar", "source": {"sha1": "556a78441b13aea4f2f4eebe0b4bcd6e9e4975f9", "sha256": "eaa61a32c78a112ab96c98aa44734be483b7ef0942c064818242303321a28197", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/scala-lang/modules/scala-xml_2.12/1.1.1/scala-xml_2.12-1.1.1-sources.jar"} , "name": "org_scala_lang_modules_scala_xml_2_12", "actual": "@org_scala_lang_modules_scala_xml_2_12//jar", "bind": "jar/org/scala_lang/modules/scala_xml_2_12"},
# duplicates in org.scala-lang:scala-library promoted to 2.12.8
# - ch.epfl.scala:bloop-config_2.12:1.2.5 wanted version 2.12.8
# - ch.epfl.scala:bloop-launcher_2.12:1.4.0-RC1 wanted version 2.12.8
# - com.chuusai:shapeless_2.12:2.3.3 wanted version 2.12.4
# - com.github.alexarchambault:argonaut-shapeless_6.2_2.12:1.2.0-M10 wanted version 2.12.8
# - io.circe:circe-core_2.12:0.9.3 wanted version 2.12.5
# - io.circe:circe-derivation_2.12:0.9.0-M3 wanted version 2.12.5
# - io.circe:circe-jawn_2.12:0.9.3 wanted version 2.12.5
# - io.circe:circe-numbers_2.12:0.9.3 wanted version 2.12.5
# - io.circe:circe-parser_2.12:0.9.3 wanted version 2.12.5
# - io.get-coursier:coursier-cache_2.12:1.1.0-M14 wanted version 2.12.8
# - io.get-coursier:coursier-core_2.12:1.1.0-M14 wanted version 2.12.8
# - io.get-coursier:coursier_2.12:1.1.0-M14 wanted version 2.12.8
# - org.scala-lang.modules:scala-java8-compat_2.12:0.8.0 wanted version 2.12.0
# - org.scala-lang.modules:scala-xml_2.12:1.1.1 wanted version 2.12.6
# - org.scala-lang:scala-reflect:2.12.8 wanted version 2.12.8
# - org.spire-math:jawn-parser_2.12:0.11.1 wanted version 2.12.2
# - org.typelevel:cats-core_2.12:1.0.1 wanted version 2.12.4
# - org.typelevel:cats-kernel_2.12:1.0.1 wanted version 2.12.4
# - org.typelevel:cats-macros_2.12:1.0.1 wanted version 2.12.4
# - org.typelevel:machinist_2.12:0.6.2 wanted version 2.12.0
# - org.typelevel:macro-compat_2.12:1.1.1 wanted version 2.12.0
    {"artifact": "org.scala-lang:scala-library:2.12.8", "lang": "java", "sha1": "36b234834d8f842cdde963c8591efae6cf413e3f", "sha256": "321fb55685635c931eba4bc0d7668349da3f2c09aee2de93a70566066ff25c28", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.8/scala-library-2.12.8.jar", "source": {"sha1": "45ccb865e040cbef5d5620571527831441392f24", "sha256": "11482bcb49b2e47baee89c3b1ae10c6a40b89e2fbb0da2a423e062f444e13492", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.8/scala-library-2.12.8-sources.jar"} , "name": "org_scala_lang_scala_library", "actual": "@org_scala_lang_scala_library//jar", "bind": "jar/org/scala_lang/scala_library"},
# duplicates in org.scala-lang:scala-reflect promoted to 2.12.8
# - io.argonaut:argonaut_2.12:6.2.3 wanted version 2.12.8
# - org.typelevel:machinist_2.12:0.6.2 wanted version 2.12.0
    {"artifact": "org.scala-lang:scala-reflect:2.12.8", "lang": "java", "sha1": "682d33402cdae50258afa2c0860eb54688dab610", "sha256": "4d6405395c4599ce04cea08ba082339e3e42135de9aae2923c9f5367e957315a", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/scala-lang/scala-reflect/2.12.8/scala-reflect-2.12.8.jar", "source": {"sha1": "2b4a5bbdc19f8ab34d474f30dbca957addc8ae09", "sha256": "5c676791217d9b48560496556b8965cceabcbfdbb65bbebdc52e99c0a3847735", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/scala-lang/scala-reflect/2.12.8/scala-reflect-2.12.8-sources.jar"} , "name": "org_scala_lang_scala_reflect", "actual": "@org_scala_lang_scala_reflect//jar", "bind": "jar/org/scala_lang/scala_reflect"},
    {"artifact": "org.spire-math:jawn-parser_2.12:0.11.1", "lang": "java", "sha1": "e49f4a6294af0821d5348ad9f89a5ce8455fc1b3", "sha256": "a442dc3a1f399a0c1d5245e5b09ac292b01c5794ee303443efa3c8a625cbd6c4", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/spire-math/jawn-parser_2.12/0.11.1/jawn-parser_2.12-0.11.1.jar", "source": {"sha1": "c67e7b5df2d07cc6495237218ca03a9ffa875242", "sha256": "7541d3cbde1c37f0bc75971608d717a9223bb8dd879c96fc0256718eed4220dd", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/spire-math/jawn-parser_2.12/0.11.1/jawn-parser_2.12-0.11.1-sources.jar"} , "name": "org_spire_math_jawn_parser_2_12", "actual": "@org_spire_math_jawn_parser_2_12//jar", "bind": "jar/org/spire_math/jawn_parser_2_12"},
    {"artifact": "org.typelevel:cats-core_2.12:1.0.1", "lang": "java", "sha1": "5872b9db29c3e1245f841ac809d5d64b9e56eaa1", "sha256": "9e1d264f3366f6090b17ebdf4fab7488c9491a7c82bc400b1f6ec05f39755b63", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/typelevel/cats-core_2.12/1.0.1/cats-core_2.12-1.0.1.jar", "source": {"sha1": "a59993540e8aaa8b7b5941642665e69e0748b08f", "sha256": "343630226130389da2a040c1ee16fc1e0c4be625b19b2591763e0d20236a3b9f", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/typelevel/cats-core_2.12/1.0.1/cats-core_2.12-1.0.1-sources.jar"} , "name": "org_typelevel_cats_core_2_12", "actual": "@org_typelevel_cats_core_2_12//jar", "bind": "jar/org/typelevel/cats_core_2_12"},
    {"artifact": "org.typelevel:cats-kernel_2.12:1.0.1", "lang": "java", "sha1": "977ec6bbc1677502d0f6c26beeb0e5ee6c0da0ad", "sha256": "d87025b6fb7f403d767f6fa726c1626c9c713927bdc6b2a58ac07a32fec7490d", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/typelevel/cats-kernel_2.12/1.0.1/cats-kernel_2.12-1.0.1.jar", "source": {"sha1": "b26244b22edd48e9173e1cae03d01244d597330d", "sha256": "4cfb3519fc4c7c6da339c614704cee1a9fa89357821ad9626b662dc7b5b963b9", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/typelevel/cats-kernel_2.12/1.0.1/cats-kernel_2.12-1.0.1-sources.jar"} , "name": "org_typelevel_cats_kernel_2_12", "actual": "@org_typelevel_cats_kernel_2_12//jar", "bind": "jar/org/typelevel/cats_kernel_2_12"},
    {"artifact": "org.typelevel:cats-macros_2.12:1.0.1", "lang": "java", "sha1": "89374609c1ffe142c7fec887883aff779befb101", "sha256": "c17a5625d9a203fa4676cb80ba22f65e68d18497945d24370bac9123ddc3da28", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/typelevel/cats-macros_2.12/1.0.1/cats-macros_2.12-1.0.1.jar", "source": {"sha1": "412d4e8cae3b7aeca5e841712ef57ec614d01c4e", "sha256": "456b745024e4836a78967f9edb9e5db09a7af352ad161b44188960be90d22702", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/typelevel/cats-macros_2.12/1.0.1/cats-macros_2.12-1.0.1-sources.jar"} , "name": "org_typelevel_cats_macros_2_12", "actual": "@org_typelevel_cats_macros_2_12//jar", "bind": "jar/org/typelevel/cats_macros_2_12"},
    {"artifact": "org.typelevel:machinist_2.12:0.6.2", "lang": "java", "sha1": "a0e8521deafd0d24c18460104eee6ce4c679c779", "sha256": "b7e97638fa25ba02414b9b8387e9ecc2ea2fce4c9d9068ac3108ee5718b477a9", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/typelevel/machinist_2.12/0.6.2/machinist_2.12-0.6.2.jar", "source": {"sha1": "98df07f657cb11f112eb84070da52e3951461ab6", "sha256": "739d6899f54e3c958d853622aec7e5198a719a2906faa50199189b0289ebef83", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/typelevel/machinist_2.12/0.6.2/machinist_2.12-0.6.2-sources.jar"} , "name": "org_typelevel_machinist_2_12", "actual": "@org_typelevel_machinist_2_12//jar", "bind": "jar/org/typelevel/machinist_2_12"},
    {"artifact": "org.typelevel:macro-compat_2.12:1.1.1", "lang": "java", "sha1": "ed809d26ef4237d7c079ae6cf7ebd0dfa7986adf", "sha256": "8b1514ec99ac9c7eded284367b6c9f8f17a097198a44e6f24488706d66bbd2b8", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/typelevel/macro-compat_2.12/1.1.1/macro-compat_2.12-1.1.1.jar", "source": {"sha1": "ade6d6ec81975cf514b0f9e2061614f2799cfe97", "sha256": "c748cbcda2e8828dd25e788617a4c559abf92960ef0f92f9f5d3ea67774c34c8", "repository": "https://repo1.maven.org/maven2/", "url": "https://repo1.maven.org/maven2/org/typelevel/macro-compat_2.12/1.1.1/macro-compat_2.12-1.1.1-sources.jar"} , "name": "org_typelevel_macro_compat_2_12", "actual": "@org_typelevel_macro_compat_2_12//jar", "bind": "jar/org/typelevel/macro_compat_2_12"},
    ]

def maven_dependencies(callback = jar_artifact_callback):
    for hash in list_dependencies():
        callback(hash)
