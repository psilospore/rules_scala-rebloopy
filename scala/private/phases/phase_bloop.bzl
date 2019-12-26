#
# PHASE: phase bloop
#
# Outputs to format the scala files when it is explicitly specified
#
def phase_bloop(ctx, p):
    args = ctx.actions.args()
    args.add("--flag")
    args.add("hi")
    ctx.actions.run(
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



