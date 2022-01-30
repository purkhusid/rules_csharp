"""
Rules for compiling C# binaries.
"""

load("//dotnet/private:providers.bzl", "AnyTargetFrameworkInfo")
load("//dotnet/private:actions/csharp_assembly.bzl", "AssemblyAction")
load(
    "//dotnet/private:common.bzl",
    "is_debug",
)
load("//dotnet/private:rules/common/binary.bzl", "build_binary")
load("//dotnet/private:rules/common/attrs.bzl", "CSHARP_BINARY_COMMON_ATTRS")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

def _compile_action(ctx, tfm, stdrefs, runtimeconfig, depsjson):
    return AssemblyAction(
        ctx.actions,
        additionalfiles = ctx.files.additionalfiles,
        analyzers = ctx.attr.analyzers,
        debug = is_debug(ctx),
        defines = ctx.attr.defines,
        deps = ctx.attr.deps + stdrefs,
        internals_visible_to = ctx.attr.internals_visible_to,
        keyfile = ctx.file.keyfile,
        langversion = ctx.attr.langversion,
        resources = ctx.files.resources,
        srcs = ctx.files.srcs,
        out = ctx.attr.out,
        target = "exe",
        target_name = ctx.attr.name,
        target_framework = tfm,
        toolchain = ctx.toolchains["@rules_dotnet//dotnet/private:toolchain_type"],
        runtimeconfig = runtimeconfig,
        depsjson = depsjson,
    )

def _binary_private_impl(ctx):
    return build_binary(ctx, _compile_action)

csharp_binary = rule(
    _binary_private_impl,
    doc = """Compile a C# exe""",
    attrs = dicts.add(
        CSHARP_BINARY_COMMON_ATTRS,
        {
            "_apphost_shimmer": attr.label(
                default = "@rules_dotnet//dotnet/private/tools/apphost_shimmer:apphost_shimmer",
                providers = AnyTargetFrameworkInfo,
                executable = True,
                cfg = "exec",
            ),
            "use_apphost_shim": attr.bool(
                doc = "Whether to create a executable shim for the binary.",
                default = True,
            ),
        },
    ),
    executable = True,
    toolchains = [
        "@rules_dotnet//dotnet/private:toolchain_type",
    ],
)

csharp_binary_without_shim = rule(
    _binary_private_impl,
    doc = """Compile a C# exe. 
This rule is internal only and is only used to compile the apphost shimmer. 
It is needed to remove a circular dependency between csharp_binary and the apphost shimmer when building the apphost shimmer""",
    attrs = dicts.add(
        CSHARP_BINARY_COMMON_ATTRS,
        {
            "use_apphost_shim": attr.bool(
                doc = "Whether to create a executable shim for the binary.",
                default = False,
            ),
        },
    ),
    executable = True,
    toolchains = [
        "@rules_dotnet//dotnet/private:toolchain_type",
        "@bazel_tools//tools/sh:toolchain_type",
    ],
)
