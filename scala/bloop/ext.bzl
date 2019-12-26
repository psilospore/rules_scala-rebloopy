load(
    "//scala:providers.bzl",
    _ScalaRulePhase = "ScalaRulePhase",
)
load(
    "//scala/private:phases/phases.bzl",
    _phase_bloop = "phase_bloop",
)

ext_add_phase_bloop = {
    "attrs": {
#        "config": attr.label(
#            allow_single_file = [".conf"],
#            default = "@bloop_default//:config",
#            doc = "The bloop configuration file.",
#        ),
        "_bloop": attr.label(
            cfg = "host",
            default = "//scala/bloop",
            executable = True,
        ),
#        "_runner": attr.label(
#            allow_single_file = True,
#            default = "//scala/bloop:runner",
#        ),
#        "_testrunner": attr.label(
#            allow_single_file = True,
#            default = "//scala/bloop:testrunner",
#        ),
#        "format": attr.bool(
#            default = False,
#        ),
    },
    "outputs": {
        "bloop_runner": "%{name}.format",
        "bloop_testrunner": "%{name}.format-test",
    },
    "phase_providers": [
        "//scala/bloop:add_phase_bloop",
    ],
}

def _add_phase_bloop_singleton_implementation(ctx):
    return [
        _ScalaRulePhase(
            phases = [
                #TODO plan is to make it a phase at the end then replace it later. Use phases before compile.
                #("=", "compile", "bloop", _phase_bloop),
                ("$", "", "bloop", _phase_bloop)
            ],
        ),
    ]

add_phase_bloop_singleton = rule(
    implementation = _add_phase_bloop_singleton_implementation,
)
