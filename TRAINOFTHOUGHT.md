# Ignore this

Find dep name
```
bazel query '//external:*' | grep bsp
```

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



So previously things pointed to the real location of sources and coursier artifacts

It's hard to do that now. What if I generate the bloop config files.
But out will point to .bloop-out/
.bloop will sym link to bazel-bin/bloop/

Wait but then bloop compile won't work becuase it will point to the bazel sources which don't change. Maybe that is fine.

Every rule will generate a config. Then it will be needed by dependent rules.

So B will generate ABC:B.config and point to ABC:A.config



```json
{
    "version" : "1.1.2",
    "project" : {
        "name" : "A",
        "directory" : "/Users/syedajafri/dev/millworkspace/A", 
        "sources" : [
            "/Users/syedajafri/dev/millworkspace/A/src"
        ],
        "dependencies" : [
        ],
        "classpath" : [
            "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.10/scala-library-2.12.10.jar"
        ],
        "out" : "/Users/syedajafri/dev/millworkspace/.bloop/out/A",
        "classesDir" : "/Users/syedajafri/dev/millworkspace/.bloop/out/A/classes",
        "resources" : [
            "/Users/syedajafri/dev/millworkspace/A/resources"
        ],
        "scala" : {
            "organization" : "org.scala-lang",
            "name" : "scala-compiler",
            "version" : "2.12.10",
            "options" : [
            ],
            "jars" : [
                "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-compiler/2.12.10/scala-compiler-2.12.10.jar",
                "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-reflect/2.12.10/scala-reflect-2.12.10.jar",
                "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/modules/scala-xml_2.12/1.0.6/scala-xml_2.12-1.0.6.jar",
                "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.10/scala-library-2.12.10.jar"
            ]
        },
        "java" : {
            "options" : [
            ]
        },
        "platform" : {
            "name" : "jvm",
            "config" : {
                "home" : "/Library/Java/JavaVirtualMachines/jdk1.8.0_231.jdk/Contents/Home",
                "options" : [
                ]
            },
            "mainClass" : [
            ]
        },
        "resolution" : {
            "modules" : [
                {
                    "organization" : "org.scala-lang",
                    "name" : "scala-library",
                    "version" : "2.12.10",
                    "artifacts" : [
                        {
                            "name" : "scala-library",
                            "path" : "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.10/scala-library-2.12.10.jar"
                        },
                        {
                            "name" : "scala-library",
                            "classifier" : "sources",
                            "path" : "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.10/scala-library-2.12.10-sources.jar"
                        }
                    ]
                }
            ]
        }
    }
}
```


Hmm seems like I can get the real path of source cna I do that to external?

This works:
```json
{
    "version" : "1.1.2",
    "project" : {
        "name" : "ABC:A",
        "directory" : "/Users/syedajafri/dev/bazelExample/A",
        "sources" : [
            "/Users/syedajafri/dev/bazelExample/ABC/A.scala"
        ],
        "dependencies" : [
        ],
        "classpath" : [
            "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-compiler/2.11.12/scala-compiler-2.11.12.jar",
            "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-library/2.11.12/scala-library-2.11.12.jar",
            "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-reflect/2.11.12/scala-reflect-2.11.12.jar"
        ],
        "out" : "/Users/syedajafri/dev/bazelExample/.bloop/out/ABC:A",
        "classesDir" : "/Users/syedajafri/dev/bazelExample/.bloop/out/ABC:A/classes",
        "scala" : {
            "organization" : "org.scala-lang",
            "name" : "scala-compiler",
            "version" : "2.11.12",
            "options" : [
            ],
            "jars" : [
                "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-compiler/2.11.12/scala-compiler-2.11.12.jar",
                "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-library/2.11.12/scala-library-2.11.12.jar",
                "/Users/syedajafri/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-reflect/2.11.12/scala-reflect-2.11.12.jar"
            ]
        }
    }
}

```


But this does not:


```json
{
    "version" : "1.1.2",
    "project" : {
        "name" : "ABC:A",
        "directory" : "/Users/syedajafri/dev/bazelExample/A",
        "sources" : [
            "/Users/syedajafri/dev/bazelExample/ABC/A.scala"
        ],
        "dependencies" : [
        ],
        "classpath" : [
            "/private/var/tmp/_bazel_syedajafri/ad86228950bcb07c687f46ad51824bd1/external/io_bazel_rules_scala_scala_compiler/scala-compiler-2.11.12.jar",
            "/private/var/tmp/_bazel_syedajafri/ad86228950bcb07c687f46ad51824bd1/external/io_bazel_rules_scala_scala_library/scala-library-2.11.12.jar",
            "/private/var/tmp/_bazel_syedajafri/ad86228950bcb07c687f46ad51824bd1/external/io_bazel_rules_scala_scala_reflect/scala-reflect-2.11.12.jar"
        ],
        "out" : "/Users/syedajafri/dev/bazelExample/.bloop/out/ABC:A",
        "classesDir" : "/Users/syedajafri/dev/bazelExample/.bloop/out/ABC:A/classes",
        "scala" : {
            "organization" : "org.scala-lang",
            "name" : "scala-compiler",
            "version" : "2.11.12",
            "options" : [
            ],
            "jars" : [
                "/private/var/tmp/_bazel_syedajafri/ad86228950bcb07c687f46ad51824bd1/external/io_bazel_rules_scala_scala_compiler/scala-compiler-2.11.12.jar",
                "/private/var/tmp/_bazel_syedajafri/ad86228950bcb07c687f46ad51824bd1/external/io_bazel_rules_scala_scala_library/scala-library-2.11.12.jar",
                "/private/var/tmp/_bazel_syedajafri/ad86228950bcb07c687f46ad51824bd1/external/io_bazel_rules_scala_scala_reflect/scala-reflect-2.11.12.jar"
            ]
        }
    }
}
```



Gave up switched to 2.11.12 and it works
Seems like the jars are different from `coursier fetch "org.scala-lang:scala-compiler:2.11.12"`


I see the compiler classpath is available for unused_deps_anal


Alright so now I got it working for one project


At the end I can compare bazel out to the previous bazel out

Ok so now I just need 