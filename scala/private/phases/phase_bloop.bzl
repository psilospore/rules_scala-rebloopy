
# Modified from https://github.com/google/subpar/blob/master/debug.bzl
def dump(obj, obj_name):
    """Debugging method that recursively prints object fields to stderr
    Args:
      obj: Object to dump
      obj_name: Name to print for that object
    Example Usage:
    ```
    load("debug", "dump")
    ...
    dump(ctx, "ctx")
    ```
    Example Output:
    ```
    WARNING: /code/rrrrr/subpar/debug.bzl:11:5:
    ctx[ctx]:
        action[string]: <getattr(action) failed>
        attr[struct]:
            _action_listener[list]: []
            _compiler[RuleConfiguredTarget]:
                data_runfiles[runfiles]:
    ```
    """

    s = '\n' + _dumpstr(obj, obj_name)
    print(s)

def _dumpstr(root_obj, root_obj_name):
    """Helper method for dump() to just generate the string
    Some fields always raise errors if we getattr() on them.  We
    manually blacklist them here.  Other fields raise errors only if
    we getattr() without a default.  Those are handled below.
    A bug was filed against Bazel, but it got fixed in a way that
    didn't actually fix this.
    """

    BLACKLIST = [
        "InputFileConfiguredTarget.output_group",
        "Label.Label",
        "Label.relative",
        "License.to_json",
        "RuleConfiguredTarget.output_group",
        "ctx.action",
        "ctx.check_placeholders",
        "ctx.empty_action",
        "ctx.expand",
        "ctx.expand_location",
        "ctx.expand_make_variables",
        "ctx.file_action",
        "ctx.middle_man",
        "ctx.new_file",
        "ctx.resolve_command",
        "ctx.rule",
        "ctx.runfiles",
        "ctx.build_setting_value",
        "ctx.aspect_ids",
        "scala_library",
        "swift",
        "ctx.template_action",
        "ctx.tokenize",
        "fragments.apple",
        "fragments.cpp",
        "fragments.java",
        "fragments.jvm",
        "fragments.objc",
        "fragments.swift",
        "fragments.py",
        "fragments.proto",
        "fragments.j2objc",
        "fragments.android",
        "runfiles.symlinks",
        "struct.output_licenses",
        "struct.to_json",
        "struct.to_proto",
    ]

    appendsCtx = ["_action_listener", "_bloop", "_code_coverage_instrumentation_worker", "_config_dependencies", "_dependency_analyzer_plugin", "_exe", "_host_javabase", "_java_runtime", "_java_toolchain", "_phase_providers", "_scala_toolchain", "_scalac", "_singlejar", "_unused_dependency_checker_plugin", "_zipper", "compatible_with", "data", "deps", "exec_compatible_with", "exports", "plugins", "resource_jars", "resources", "restricted_to", "runtime_deps", "srcs", "to_json", "to_proto", "toolchains", "unused_dependency_checker_ignored_targets"]

#    for a in appendsCtx:
#        BLACKLIST.append("ctx." + a)

#    print(BLACKLIST)
    MAXLINES = 4000
    ROOT_MAXDEPTH = 5

    # List of printable lines
    lines = []

    # Bazel doesn't allow a function to recursively call itself, so
    # use an explicit stack
    stack = [(root_obj, root_obj_name, 0, ROOT_MAXDEPTH)]
    # No while() in Bazel, so use for loop over large range
    for _ in range(MAXLINES):
        if len(stack) == 0:
            break
        obj, obj_name, indent, maxdepth = stack.pop()

        obj_type = type(obj)
        indent_str = ' '*indent
        line = '{indent_str}{obj_name}[{obj_type}]:'.format(
            indent_str=indent_str, obj_name=obj_name, obj_type=obj_type)

        if maxdepth == 0 or obj_type in ['dict', 'list', 'set', 'string']:
            # Dump value as string, inline
            line += ' ' + str(obj)
        else:
            # Dump all of value's fields on separate lines
            attrs = dir(obj)
#            print(attrs)
            # Push each field to stack in reverse order, so they pop
            # in sorted order
            for attr in reversed(attrs):
#                print("%s.%s" % (obj_type, attr))
                if "%s.%s" % (obj_type, attr) in BLACKLIST:
                    value = '<blacklisted attr (%s)>' % attr
                else:
                    value = getattr(obj, attr, '<getattr(%s) failed>' % attr)
                stack.append((value, attr, indent+4, maxdepth-1))
        lines.append(line)
    return '\n'.join(lines)

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

    args.add_joined([dep.path for dep in p.collect_jars.transitive_compile_jars.to_list() if ROOT_NAME in dep.owner.workspace_root], join_with=", ") #TODO just check for empty or not?

#    args.add_all("--compiler_classpath", [dep.path for dep in p.collect_jars.transitive_compile_jars.to_list() if ROOT_NAME in dep.owner.workspace_root]) #TODO just check for empty or not?

    # Not helpful only has scala_library
#    dump(ctx.attr._scala_toolchain[0].files, "_scala_toolchain")
#    print(ctx.attr._scala_toolchain[0].files.to_list()[0].path)
    print("HI")
    args.add_joined("--target_classpath", p.collect_jars.transitive_compile_jars.to_list(), join_with=", ")

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



