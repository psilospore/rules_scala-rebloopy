#
# PHASE: phase scalafmt
#
# Outputs to format the scala files when it is explicitly specified
#
def phase_scalafmt(ctx, p):
    if ctx.attr.format:
        manifest, files = _build_format(ctx)
        _formatter(ctx, manifest, files, ctx.file._runner, ctx.outputs.scalafmt_runner)
        _formatter(ctx, manifest, files, ctx.file._testrunner, ctx.outputs.scalafmt_testrunner)
    else:
        ctx.actions.write(
            output = ctx.outputs.scalafmt_runner,
            content = "",
            is_executable = True,
        )
        ctx.actions.write(
            output = ctx.outputs.scalafmt_testrunner,
            content = "",
            is_executable = True,
        )

def _build_format(ctx):
    files = []
    runner_inputs, _, runner_manifests = ctx.resolve_command(tools = [ctx.attr._fmt])
    manifest_content = []
    for src in ctx.files.srcs:
        if src.path.endswith(".scala") and src.is_source:
            file = ctx.actions.declare_file(src.short_path)
            files.append(file)
            args = ctx.actions.args()
            args.add("--config")
            args.add(ctx.file.config.path)
            args.add(src.path)
            args.add(file.path)
            args.set_param_file_format("multiline")
            args.use_param_file("@%s", use_always = True)
            ctx.actions.run(
                arguments = ["--jvm_flag=-Dfile.encoding=UTF-8", args],
                executable = ctx.executable._fmt,
                outputs = [file],
                input_manifests = runner_manifests,
                inputs = [ctx.file.config, src],
                tools = runner_inputs,
                execution_requirements = {"supports-workers": "1"},
                mnemonic = "ScalaFmt",
            )
            manifest_content.append("{} {}".format(src.short_path, file.short_path))

    manifest = ctx.actions.declare_file("format/{}/manifest.txt".format(ctx.label.name))
    ctx.actions.write(manifest, "\n".join(manifest_content) + "\n")

    return manifest, files

def _formatter(ctx, manifest, files, input_runner, output_runner):
    ctx.actions.run_shell(
        inputs = [input_runner, manifest] + files,
        outputs = [output_runner],
        command = "cat $1 | sed -e s#%workspace%#$2# -e s#%manifest%#$3# > $4",
        arguments = [
            input_runner.path,
            ctx.workspace_name,
            manifest.short_path,
            output_runner.path,
        ],
        execution_requirements = {},
    )
