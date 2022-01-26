"""
Rules for compiling NUnit tests.
"""

load("//dotnet/private:rules/csharp/binary_private.bzl", "csharp_binary_private")

def csharp_nunit_test(**kwargs):
    deps = kwargs.pop("deps", []) + [
        "@NUnitLite//:nunitlite",
        "@NUnit//:nunit.framework",
    ]

    srcs = kwargs.pop("srcs", []) + [
        "@rules_dotnet//dotnet/private:nunit/shim.cs",
    ]

    csharp_binary_private(
        srcs = srcs,
        deps = deps,
        winexe = False,  # winexe doesn't make sense for tests
        **kwargs
    )
