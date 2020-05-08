load("@io_bazel_rules_scala//scala:jars_to_labels.bzl", "JarsToLabelsInfo")
load("@io_bazel_rules_scala//scala:plusone.bzl", "PlusOneDeps")

load("//tools:dump.bzl", "dump")

def write_manifest(ctx):
    main_class = getattr(ctx.attr, "main_class", None)
    write_manifest_file(ctx.actions, ctx.outputs.manifest, main_class)

def write_manifest_file(actions, output_file, main_class):
    # TODO(bazel-team): I don't think this classpath is what you want
    manifest = "Class-Path: \n"
    if main_class:
        manifest += "Main-Class: %s\n" % main_class

    actions.write(output = output_file, content = manifest)

def collect_srcjars(targets):
    srcjars = []
    for target in targets:
        if hasattr(target, "srcjars"):
            srcjars.append(target.srcjars.srcjar)
    return depset(srcjars)

def collect_jars(
        dep_targets,
        dependency_analyzer_is_off = True,
        unused_dependency_checker_is_off = True,
        plus_one_deps_is_off = True):
    """Compute the runtime and compile-time dependencies from the given targets"""  # noqa

    if dependency_analyzer_is_off:
        return _collect_jars_when_dependency_analyzer_is_off(
            dep_targets,
            unused_dependency_checker_is_off,
            plus_one_deps_is_off,
        )
    else:
        return _collect_jars_when_dependency_analyzer_is_on(dep_targets)

def collect_plugin_paths(plugins):
    """Get the actual jar paths of plugins as a depset."""
    paths = []
    for p in plugins:
        if hasattr(p, "path"):
            paths.append(p)
        elif JavaInfo in p:
            paths.extend([j.class_jar for j in p[JavaInfo].outputs.jars])
            # support http_file pointed at a jar. http_jar uses ijar,
            # which breaks scala macros

        elif hasattr(p, "files"):
            paths.extend([f for f in p.files.to_list() if not_sources_jar(f.basename)])
    return depset(paths)

def _collect_jars_when_dependency_analyzer_is_off(
        dep_targets,
        unused_dependency_checker_is_off,
        plus_one_deps_is_off):

    print("in _collect_jars_when_dependency_analyzer_is_off")

    compile_jars = []
    plus_one_deps_compile_jars = []
    runtime_jars = []
    jars2labels = {}

    deps_providers = []


#    dump(dep_targets, "dep_targets")

    for dep_target in dep_targets:
        # we require a JavaInfo for dependencies
        # must use java_import or scala_import if you have raw files
        java_provider = dep_target[JavaInfo]
        deps_providers.append(java_provider)
        compile_jars.append(java_provider.compile_jars)
        runtime_jars.append(java_provider.transitive_runtime_jars)

        if not unused_dependency_checker_is_off:
            add_labels_of_jars_to(
                jars2labels,
                dep_target,
                [],
                java_provider.compile_jars.to_list(),
            )

        if (not plus_one_deps_is_off) and (PlusOneDeps in dep_target):
            plus_one_deps_compile_jars.append(
                depset(transitive = [dep[JavaInfo].compile_jars for dep in dep_target[PlusOneDeps].direct_deps if JavaInfo in dep]),
            )


#    dump(compile_jars, "compile_jars")
#    dump(runtime_jars, "runtime_jars")
#    dump(plus_one_deps_compile_jars, "plus_one_deps_compile_jars")
#    [][1]


    return struct(
        compile_jars = depset(transitive = compile_jars),
        transitive_runtime_jars = depset(transitive = runtime_jars),
        jars2labels = JarsToLabelsInfo(jars_to_labels = jars2labels),
        transitive_compile_jars = depset(transitive = compile_jars + plus_one_deps_compile_jars),
        deps_providers = deps_providers,
    )

def _collect_jars_when_dependency_analyzer_is_on(dep_targets):
    transitive_compile_jars = []
    jars2labels = {}
    compile_jars = []
    runtime_jars = []
    deps_providers = []

    print("in _collect_jars_when_dependency_analyzer_is_on")

    for dep_target in dep_targets:
        # we require a JavaInfo for dependencies
        # must use java_import or scala_import if you have raw files
        java_provider = dep_target[JavaInfo]
        deps_providers.append(java_provider)
        current_dep_compile_jars = java_provider.compile_jars
        current_dep_transitive_compile_jars = java_provider.transitive_compile_time_jars
        runtime_jars.append(java_provider.transitive_runtime_jars)

        compile_jars.append(current_dep_compile_jars)
        transitive_compile_jars.append(current_dep_transitive_compile_jars)

        add_labels_of_jars_to(
            jars2labels,
            dep_target,
            current_dep_transitive_compile_jars.to_list(),
            current_dep_compile_jars.to_list(),
        )

    return struct(
        compile_jars = depset(transitive = compile_jars),
        transitive_runtime_jars = depset(transitive = runtime_jars),
        jars2labels = JarsToLabelsInfo(jars_to_labels = jars2labels),
        transitive_compile_jars = depset(transitive = transitive_compile_jars),
        deps_providers = deps_providers,
    )

# When import mavan_jar's for scala macros we have to use the jar:file requirement
# since bazel 0.6.0 this brings in the source jar too
# the scala compiler thinks a source jar can look like a package space
# causing a conflict between objects and packages warning
#  error: package cats contains object and package with same name: implicits
# one of them needs to be removed from classpath
# import cats.implicits._

def not_sources_jar(name):
    return "-sources.jar" not in name

def filter_not_sources(deps):
    return depset(
        [dep for dep in deps.to_list() if not_sources_jar(dep.basename)],
    )

def add_labels_of_jars_to(jars2labels, dependency, all_jars, direct_jars):
    for jar in direct_jars:
        jars2labels[jar.path] = dependency.label
    for jar in all_jars:
        path = jar.path
        if path not in jars2labels:
            # skylark exposes only labels of direct dependencies.
            # to get labels of indirect dependencies we collect them from the providers transitively
            label = _provider_of_dependency_label_of(dependency, path)
            if label == None:
                label = "Unknown label of file {jar_path} which came from {dependency_label}".format(
                    jar_path = path,
                    dependency_label = dependency.label,
                )
            jars2labels[path] = label

def _provider_of_dependency_label_of(dependency, path):
    if JarsToLabelsInfo in dependency:
        return dependency[JarsToLabelsInfo].jars_to_labels.get(path)
    else:
        return None

def sanitize_string_for_usage(s):
    res_array = []
    for idx in range(len(s)):
        c = s[idx]
        if c.isalnum() or c == ".":
            res_array.append(c)
        else:
            res_array.append("_")
    return "".join(res_array)
