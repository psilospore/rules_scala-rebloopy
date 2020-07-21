load("//tools:dump.bzl", "dump")

# Used to collect dependencies for bloop projects
BloopInfo = provider(fields = [
    "projectName",
    "projectDeps"
])

# PHASE: phase bloop
def phase_bloop(ctx, p):

    projectName = "%s:%s" % (ctx.label.package, ctx.label.name)
    directProjectDeps = [dep[BloopInfo].projectName for dep in ctx.attr.deps]
    transitive_bloop_deps = [dep[BloopInfo].projectDeps for dep in ctx.attr.deps]
    projectDeps = depset(directProjectDeps, transitive = transitive_bloop_deps, order = "preorder")

    args = ctx.actions.args()

    args = ctx.actions.args()
    args.add("--label", projectName)
    args.add_all("--sources", ctx.files.srcs)

    dependencyJars = p.collect_jars.transitive_runtime_jars.to_list()
    args.add_joined("--targetClasspath", dependencyJars, join_with=", ")
    args.add_joined("--bloopDependencies", projectDeps.to_list(), join_with=", " )

    print("Label: %s depends on" % projectName)
    print(projectDeps.to_list())

    args.add("--manifest", ctx.outputs.manifest.path)

    full_jars = ctx.actions.declare_file(ctx.label.name + ".jar")
    args.add("--jarOut", full_jars.path)

    statsfile = ctx.actions.declare_file(ctx.label.name + ".statsfile")
    args.add("--statsfile", statsfile)

    args.set_param_file_format("multiline")
    args.use_param_file("@%s", use_always = True)

    # this seems to nest it under the package it is in. e.g. //ABC:A //ABC:B //BC_Z_disjoint:B then there is a ABC/.bloop and BC_Z_disjoint/.bloop
    # So the targets are still in one .bloop for the package
    # Oh the docs mention it'll create it for the current package
    # So initialize bloop for each package?
    bloopProjectConfig = ctx.actions.declare_file(".bloop/" + projectName + ".json")
    args.add("--bloopProjectConfig", ctx.build_file_path)
    bloopProjectOutput = ctx.actions.declare_directory(".bloop/out/" + projectName)
    args.add("--bloopProjectOutput", ctx.build_file_path)

    ctx.actions.run(
        outputs = [full_jars, statsfile, bloopProjectConfig, bloopProjectOutput],
        inputs = [ctx.outputs.manifest] +  dependencyJars,
        arguments = ["--jvm_flag=-Dfile.encoding=UTF-8", args],
        executable = ctx.executable._bloop, # Run bloop runner with args
        execution_requirements = {"supports-workers": "1"},
        progress_message = "Bloop Runner for %s" % ctx.label,
        mnemonic = "Bloop"
    )

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

    rjars = p.collect_jars.transitive_runtime_jars

    bloop_deps = BloopInfo(projectName = projectName, projectDeps = projectDeps)

    return struct(
        full_jars = [full_jars],
        rjars = depset([full_jars], transitive = [rjars]),
        merged_provider = scala_compilation_provider,
        external_providers = {
            "JavaInfo": scala_compilation_provider,
            "BloopInfo": bloop_deps
        }
    )
