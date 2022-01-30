"""
Rules for compiling C# libraries.
"""

load("//dotnet/private:actions/csharp_assembly.bzl", "AssemblyAction")
load("//dotnet/private:rules/common/library.bzl", "build_library")
load("//dotnet/private:rules/common/attrs.bzl", "CSHARP_COMMON_ATTRS")
load(
    "//dotnet/private:common.bzl",
    "is_debug",
)

def _compile_action(ctx, tfm, stdrefs):
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
        target = "library",
        target_name = ctx.attr.name,
        target_framework = tfm,
        toolchain = ctx.toolchains["@rules_dotnet//dotnet/private:toolchain_type"],
    )

def _library_impl(ctx):
    return build_library(ctx, _compile_action)

csharp_library = rule(
    _library_impl,
    doc = "Compile a C# DLL",
    attrs = CSHARP_COMMON_ATTRS,
    executable = False,
    toolchains = ["@rules_dotnet//dotnet/private:toolchain_type"],
)
