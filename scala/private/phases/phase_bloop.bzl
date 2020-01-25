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

    args = ctx.actions.args()
    args.add("--label", labelName)
    args.add_all("--sources", ctx.files.srcs)

    args.add_joined("--target_classpath", p.collect_jars.transitive_runtime_jars.to_list(), join_with=", ")

    args.add("--build_file_path", ctx.build_file_path)
    args.add("--bloopDir", "/Users/syedajafri/dev/bazelExample/") # TODO how can I pass this like in higherkindness? ctx.file.persistence_dir.path)

    args.set_param_file_format("multiline")
    args.use_param_file("@%s", use_always = True)

    args.add("--output", ctx.outputs.bloop_runner.path)

    ctx.actions.run(
        outputs = [ctx.outputs.bloop_runner],
        arguments = ["--jvm_flag=-Dfile.encoding=UTF-8", args],
        executable = ctx.executable._bloop, # Run bloop runner with args
        execution_requirements = {"supports-workers": "1"},
        progress_message = "Bloop Runner for %s" % ctx.label,
        mnemonic = "Bloop"
    )

    #TODO reproduce this might be able to not have some options to test it out
    dump(p.compile, "compile")

    return struct(
        findmehiiii = ctx.outputs.bloop_runner
    )

#    ctx.actions.write(
#        output = ctx.outputs.bloop_testrunner,
#        content = "",
#        is_executable = True,
#    )



