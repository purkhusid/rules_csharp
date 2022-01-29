"""
Base rule for compiling C# binaries and tests.
"""

load("//dotnet/private:providers.bzl", "AnyTargetFrameworkInfo", "GetDotnetAssemblyInfoFromLabel")
load("//dotnet/private:actions/assembly.bzl", "AssemblyAction")
load(
    "//dotnet/private:actions/misc.bzl",
    "write_depsjson",
    "write_internals_visible_to",
    "write_runtimeconfig",
)
load(
    "//dotnet/private:common.bzl",
    "fill_in_missing_frameworks",
    "is_core_framework",
    "is_debug",
    "is_standard_framework",
)
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

def _create_shim_exe(ctx, dll):
    runtime = ctx.toolchains["@rules_dotnet//dotnet/private:toolchain_type"].runtime
    apphost = ctx.toolchains["@rules_dotnet//dotnet/private:toolchain_type"].apphost
    manifest_loader = ctx.attr._manifest_loader
    output = ctx.actions.declare_file(paths.replace_extension(dll.basename, ".exe"), sibling = dll)

    ctx.actions.run(
        executable = runtime,
        arguments = [ctx.executable._apphost_shimmer.path, apphost.path, dll.path],
        inputs = [apphost, dll],
        tools = [ctx.attr._apphost_shimmer.files],
        outputs = [output],
    )

    return output

def _symlink_manifest_loader(ctx, executable):
    loader = ctx.actions.declare_file("ManifestLoader.dll", sibling = executable)
    ctx.actions.symlink(output = loader, target_file = GetDotnetAssemblyInfoFromLabel(ctx.attr._manifest_loader).out)
    return loader

def _binary_private_impl(ctx):
    providers = {}

    stdrefs = [ctx.attr._stdrefs] if ctx.attr.include_stdrefs else []

    internals_visible_to_cs = write_internals_visible_to(
        ctx.actions,
        name = ctx.attr.name,
        others = ctx.attr.internals_visible_to,
    )

    for tfm in ctx.attr.target_frameworks:
        if is_standard_framework(tfm):
            fail("It doesn't make sense to build an executable for " + tfm)

        runtimeconfig = None
        depsjson = None
        if is_core_framework(tfm):
            runtimeconfig = write_runtimeconfig(
                ctx.actions,
                template = ctx.file.runtimeconfig_template,
                name = ctx.attr.name,
                tfm = tfm,
            )
            depsjson = write_depsjson(
                ctx.actions,
                template = ctx.file.depsjson_template,
                name = ctx.attr.name,
                tfm = tfm,
            )

        providers[tfm] = AssemblyAction(
            ctx.actions,
            additionalfiles = ctx.files.additionalfiles,
            analyzers = ctx.attr.analyzers,
            debug = is_debug(ctx),
            defines = ctx.attr.defines,
            deps = ctx.attr.deps + stdrefs,
            internals_visible_to = ctx.attr.internals_visible_to,
            internals_visible_to_cs = internals_visible_to_cs,
            keyfile = ctx.file.keyfile,
            langversion = ctx.attr.langversion,
            resources = ctx.files.resources,
            srcs = ctx.files.srcs,
            out = ctx.attr.out,
            # TODO: Separate parameter for target and file extension
            target = "exe",
            target_name = ctx.attr.name,
            target_framework = tfm,
            toolchain = ctx.toolchains["@rules_dotnet//dotnet/private:toolchain_type"],
            runtimeconfig = runtimeconfig,
            depsjson = depsjson,
        )

    fill_in_missing_frameworks(ctx.attr.name, providers)

    result = providers.values()
    executable = result[0].out
    pdb = result[0].pdb
    runtimeconfig = result[0].runtimeconfig
    depsjson = result[0].depsjson

    direct_runfiles = [executable, pdb]

    if runtimeconfig != None:
        direct_runfiles.append(runtimeconfig)
    if depsjson != None:
        direct_runfiles.append(depsjson)

    manifest_loader = _symlink_manifest_loader(ctx, executable)
    direct_runfiles.append(manifest_loader)

    files = [executable, result[0].prefout, pdb]
    if ctx.attr.use_apphost_shim:
        executable = _create_shim_exe(ctx, executable)
        direct_runfiles.append(executable)
        files = files.append(executable)

    result.append(DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(
            files = direct_runfiles,
            transitive_files = result[0].transitive_runfiles,
        ),
        files = depset(files),
    ))

    return result

# TODO: Deduplicate attrs
ATTRS = {
    "srcs": attr.label_list(
        doc = "C# source files.",
        allow_files = [".cs"],
    ),
    "additionalfiles": attr.label_list(
        doc = "Extra files to configure analyzers.",
        allow_files = True,
    ),
    "analyzers": attr.label_list(
        doc = "A list of analyzer references.",
        providers = AnyTargetFrameworkInfo,
    ),
    "keyfile": attr.label(
        doc = "The key file used to sign the assembly with a strong name.",
        allow_single_file = True,
    ),
    "langversion": attr.string(
        doc = "The version string for the C# language.",
    ),
    "resources": attr.label_list(
        doc = "A list of files to embed in the DLL as resources.",
        allow_files = True,
    ),
    "out": attr.string(
        doc = "File name, without extension, of the built assembly.",
    ),
    "target_frameworks": attr.string_list(
        doc = "A list of target framework monikers to build" +
              "See https://docs.microsoft.com/en-us/dotnet/standard/frameworks",
        allow_empty = False,
    ),
    "defines": attr.string_list(
        doc = "A list of preprocessor directive symbols to define.",
        default = [],
        allow_empty = True,
    ),
    "winexe": attr.bool(
        doc = "If true, output a winexe-style executable, otherwise" +
              "output a console-style executable.",
        default = False,
    ),
    "include_stdrefs": attr.bool(
        doc = "Whether to reference @net//:StandardReferences (the default set of references that MSBuild adds to every project).",
        default = True,
    ),
    "_stdrefs": attr.label(
        doc = "The standard set of assemblies to reference.",
        default = "@net//:StandardReferences",
    ),
    "runtimeconfig_template": attr.label(
        doc = "A template file to use for generating runtimeconfig.json",
        default = ":runtimeconfig.json.tpl",
        allow_single_file = True,
    ),
    "depsjson_template": attr.label(
        doc = "A template file to use for generating deps.json",
        default = ":deps.json.tpl",
        allow_single_file = True,
    ),
    "internals_visible_to": attr.string_list(
        doc = "Other C# libraries that can see the assembly's internal symbols. Using this rather than the InternalsVisibleTo assembly attribute will improve build caching.",
    ),
    "deps": attr.label_list(
        doc = "Other C# libraries, binaries, or imported DLLs",
        providers = AnyTargetFrameworkInfo,
    ),
    "_manifest_loader": attr.label(
        default = "@rules_dotnet//dotnet/private/tools/manifest_loader:ManifestLoader",
        providers = AnyTargetFrameworkInfo,
    ),
}

csharp_binary_private = rule(
    _binary_private_impl,
    doc = """Compile a C# exe.
This is a private rule used to implement csharp_binary and should not be used directly.""",
    attrs = dicts.add(
        ATTRS,
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
    toolchains = ["@rules_dotnet//dotnet/private:toolchain_type"],
)

# This rule is requred so that we can build the AppHost shimmer and get rid of the
# circular dependency between the *_binary rule and the apphost shimmer target
csharp_binary_private_without_shim = rule(
    _binary_private_impl,
    doc = """Compile a C# exe.
This is a private rule used to implement csharp_binary and should not be used directly.""",
    attrs = dicts.add(
        ATTRS,
        {
            "use_apphost_shim": attr.bool(
                doc = "Whether to create a executable shim for the binary.",
                default = False,
            ),
        },
    ),
    executable = True,
    toolchains = ["@rules_dotnet//dotnet/private:toolchain_type"],
)
