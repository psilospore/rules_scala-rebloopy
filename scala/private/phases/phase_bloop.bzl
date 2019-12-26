load("//tools:dump.bzl", "dump")
load("//scala/private:rule_impls.bzl", "empty_coverage_struct")

# PHASE: phase bloop
def phase_bloop(ctx, p):
    args = ctx.actions.args()
    labelName = "%s:%s" % (ctx.label.package, ctx.label.name)

    args = ctx.actions.args()
    args.add("--label", labelName)
    args.add_all("--sources", ctx.files.srcs)

    args.add_joined("--target_classpath", p.collect_jars.transitive_runtime_jars.to_list(), join_with=", ")

    args.add("--build_file_path", ctx.build_file_path)
    args.add("--bloopDir", "/Users/syed.jafri/dev/local_rules_scala/") # TODO how can I pass this like in higherkindness? ctx.file.persistence_dir.path)

    args.set_param_file_format("multiline")
    args.use_param_file("@%s", use_always = True)

    args.add("--manifest", ctx.outputs.manifest.path)

    preventConflict = "" # "junk" # Used for debugging purposes. When I want to compare with the current compile phase I use this.
    full_jars = ctx.actions.declare_file(ctx.label.name + preventConflict + ".jar")
    args.add("--jarOut", full_jars.path)
    rjars = p.collect_jars.transitive_runtime_jars

    # TODO output
    statsfile = ctx.actions.declare_file(ctx.label.name + preventConflict + ".statsfile")
    args.add("--statsfile", statsfile)

    ctx.actions.run(
        outputs = [full_jars, statsfile],
        inputs = [ctx.outputs.manifest],
        arguments = ["--jvm_flag=-Dfile.encoding=UTF-8", args],
        executable = ctx.executable._bloop, # Run bloop runner with args
        execution_requirements = {"supports-workers": "1"},
        progress_message = "Bloop Runner for %s" % ctx.label,
        mnemonic = "Bloop"
    )

    if hasattr(p, "compile"):
        #TODO reproduce this might be able to not have some options to test it out
        dump(p.compile, "compile")
        print(p.compile.coverage.instrumented_files.to_json())
        dump(p.compile.rjars.to_list(), "rjars")

    # Move to create scala_compilation_provider maybe
    exports = []
    if hasattr(ctx.attr, "exports"):
        exports = [dep[JavaInfo] for dep in ctx.attr.exports]
    runtime_deps = []
    if hasattr(ctx.attr, "runtime_deps"):
        runtime_deps = [dep[JavaInfo] for dep in ctx.attr.runtime_deps]

    scala_compilation_provider = JavaInfo(
          output_jar = full_jars,
          compile_jar = full_jars,
          source_jar = None,
          deps = p.collect_jars.deps_providers,
          exports = exports,
          runtime_deps = runtime_deps,
      )

    return struct(
        full_jars = [full_jars],
        coverage = empty_coverage_struct,
        rjars = depset([full_jars], transitive = [rjars]),
        merged_provider = scala_compilation_provider

    )

#    ctx.actions.write(
#        output = ctx.outputs.bloop_testrunner,
#        content = "",
#        is_executable = True,
#    )



