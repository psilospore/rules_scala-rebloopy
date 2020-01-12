load("debug", "dump")

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
    labelName = ctx.label.name

#    args_file = ctx.actions.declare_file(labelName + ".args")

#    ctx.actions.write(
#        output = args_file,
#        content = "\n".join([               # the contents of the args file
#            "--label", labelName # , "--sources", args.add(ctx.files.srcs)
#        ])
#    )
#
#    print(args_file.path)

    args = ctx.actions.args()
    args.add("--label")
    args.add(labelName)
    args.add("--sources")
    args.add_all(depset(ctx.files.srcs, transitive = p.collect_jars.jars2labels.jars_to_labels))
    args.add("--compiler_classpath")
    args.add_all(p.collect_jars.compile_jars)

    args.set_param_file_format("multiline")
    args.use_param_file("@%s", use_always = True)


    print("Label %s" % labelName)
    print("srcs %s" % ctx.files.srcs)
    file = ctx.actions.declare_file("%s.format-test" % labelName)

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



