"""
Common implementation for building a .Net library
"""

load(
    "//dotnet/private:common.bzl",
    "fill_in_missing_frameworks",
)

# TODO: Add docs
def build_library(ctx, compile_action):
    providers = {}

    stdrefs = [ctx.attr._stdrefs] if ctx.attr.include_stdrefs else []

    for tfm in ctx.attr.target_frameworks:
        providers[tfm] = compile_action(ctx, tfm, stdrefs)

    fill_in_missing_frameworks(ctx.attr.name, providers)

    result = providers.values()
    result.append(DefaultInfo(
        files = depset([result[0].out]),
        default_runfiles = ctx.runfiles(files = [result[0].pdb]),
    ))

    return result
