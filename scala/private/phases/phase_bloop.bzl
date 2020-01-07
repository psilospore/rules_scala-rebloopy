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
    args.add("--label")
    args.add(labelName)
    args.add("--flagfile=/Users/syedajafri/dev/bazelExample/flagfile.txt")
#    args.add("/Users/syedajafri/dev/bazelExample/flagfile.txt")


    args.add(ctx.files.srcs[0].path)

    print("Label %s" % labelName)
    file = ctx.actions.declare_file("%s.format-test" % labelName)

    ctx.actions.run(
        outputs = [file],
        arguments = [args],
        executable = ctx.executable._bloop, # Run bloop runner with args
        execution_requirements = {"supports-workers": "1"},
        mnemonic = "bloop",
    )

    ctx.actions.write(
        output = ctx.outputs.bloop_runner,
        content = "",
        is_executable = True,
    )
#        ctx.actions.write(
#            output = ctx.outputs.bloop_testrunner,
#            content = "",
#            is_executable = True,
#        )



