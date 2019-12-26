# Ignore this

See https://github.com/bazelbuild/rules_scala/pull/865/files

Basically scala_library.bzl and scala_compile.bzl have an impl function that call

phase_binary_compile and phase_library_compile in phases.md


like scalafmt I'd put my own phase there

in phase_compile.bzl I can see phase_library_compile calls phase_common_compile grabing
some args from previous phases.
srcjars
buildijar

_phase_compile then compiles and returns a struct with
I suppose I would return the same struct
```
    return struct(
        class_jar = out.class_jar,
        coverage = out.coverage,
        full_jars = out.full_jars,
        ijar = out.ijar,
        ijars = out.ijars,
        rjars = depset(out.full_jars, transitive = [rjars]),
        java_jar = out.java_jar,
        source_jars = pack_source_jars(ctx) + out.source_jars,
        merged_provider = out.merged_provider,
    )
```

