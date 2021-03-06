load(
    "//scala:advanced_usage/providers.bzl",
    _ScalaRulePhase = "ScalaRulePhase",
)
load(
    "//scala/private:phases/phases.bzl",
    _phase_bloop = "phase_bloop",
)

ext_add_phase_bloop = {
    "attrs": {
#        "bloopDir": attr.label(
#            allow_single_file = True,
#            doc = "Bloop output folder",
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
    "phase_providers": [
        "//scala/bloop:add_phase_bloop",
    ],
}

def _add_phase_bloop_singleton_implementation(ctx):
    return [
        _ScalaRulePhase(
            custom_phases = [
                #TODO plan is to make it a phase at the end then replace it later. Use phases before compile.
                ("=", "compile", "compile", _phase_bloop),
#                ("$", "", "bloop", _phase_bloop)
#                ("after", "compile", "bloop", _phase_bloop)
            ],
        ),
    ]

add_phase_bloop_singleton = rule(
    implementation = _add_phase_bloop_singleton_implementation,
)
