load("//tools:dump.bzl", "dump")

#
# PHASE: phase bloop
#
# Outputs to format the scala files when it is explicitly specified
# Can use the following phases probably. Referecences them like so p.collect_jars.
#            ("scalac_provider", phase_scalac_provider),
#            ("write_manifest", phase_write_manifest),
#            ("unused_deps_checker", phase_unused_deps_checker),
#            ("collect_jars", phase_common_collect_jars),
def phase_bloop(ctx, p):
    args = ctx.actions.args()
    labelName = "%s:%s" % (ctx.label.package, ctx.label.name)

#    args_file = ctx.actions.declare_file(labelName + ".args")

#    ctx.actions.write(
#        output = args_file,
#        content = "\n".join([               # the contents of the args file
#            "--label", labelName # , "--sources", args.add(ctx.files.srcs)
#        ])
#    )
#
#    print(args_file.path)

#    dump(ctx, "ctx")

#    dump(p, "p")
# add _scala_toolchain for

    ROOT_NAME = "external/io_bazel_rules_scala"
    args = ctx.actions.args()
    args.add("--label", labelName)
    args.add_all("--sources", ctx.files.srcs)

    args.add("--compiler_classpath")

#    dump(p.collect_jars, "p.collect_jars")
#    dump(p.collect_jars.deps_providers, "HIII")

    args.add_joined([dep.path for dep in p.collect_jars.transitive_runtime_jars.to_list() if ROOT_NAME in dep.owner.workspace_root], join_with=", ") #TODO just check for empty or not?

#    args.add_all("--compiler_classpath", [dep.path for dep in p.collect_jars.transitive_compile_jars.to_list() if ROOT_NAME in dep.owner.workspace_root]) #TODO just check for empty or not?

    # Not helpful only has scala_library
#    dump(ctx.attr._scala_toolchain[0].files, "_scala_toolchain")
#    print(ctx.attr._scala_toolchain[0].files.to_list()[0].path)
    print("HI")
    args.add_joined("--target_classpath", p.collect_jars.transitive_runtime_jars.to_list(), join_with=", ")

#    for dep in p.collect_jars.transitive_compile_jars.to_list():
#        dump(dep.owner.workspace_root, "w")

#    print(p.collect_jars.compile_jars.to_list())

    args.add("--build_file_path", ctx.build_file_path)
    args.add("--bloopDir", "/Users/syedajafri/dev/bazelExample/") # TODO how can I pass this like in higherkindness? ctx.file.persistence_dir.path)


    args.set_param_file_format("multiline")
    args.use_param_file("@%s", use_always = True)

    print("Label %s" % labelName)
    print("srcs %s" % ctx.files.srcs)
    file = ctx.actions.declare_file("%s.format-test" % ctx.label.name)

    print(args)

    ctx.actions.run(
        outputs = [file],
#        inputs = ctx.files.srcs,
        arguments = ["--jvm_flag=-Dfile.encoding=UTF-8", args],
        executable = ctx.executable._bloop, # Run bloop runner with args
        execution_requirements = {"supports-workers": "1"},
        mnemonic = "Bloop"
    )

    ctx.actions.write(
        output = ctx.outputs.bloop_runner,
        content = "",
        is_executable = True,
    )
#    ctx.actions.write(
#        output = ctx.outputs.bloop_testrunner,
#        content = "",
#        is_executable = True,
#    )



