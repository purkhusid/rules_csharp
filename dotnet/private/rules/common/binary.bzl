"""
Base rule for building .Net binaries
"""

load("//dotnet/private:providers.bzl", "GetDotnetAssemblyInfoFromLabel")
load(
    "//dotnet/private:actions/misc.bzl",
    "write_depsjson",
    "write_runtimeconfig",
)
load(
    "//dotnet/private:common.bzl",
    "fill_in_missing_frameworks",
    "is_core_framework",
    "is_standard_framework",
)
load("//dotnet/private:windows_utils.bzl", "is_windows", "create_windows_native_launcher_script")
load("@bazel_skylib//lib:paths.bzl", "paths")

def _create_shim_exe(ctx, dll):
    runtime = ctx.toolchains["@rules_dotnet//dotnet/private:toolchain_type"].runtime
    apphost = ctx.toolchains["@rules_dotnet//dotnet/private:toolchain_type"].apphost
    manifest_loader = ctx.attr._manifest_loader
    output = ctx.actions.declare_file(paths.replace_extension(dll.basename, ".exe"), sibling = dll)

    ctx.actions.run(
        executable = runtime.files_to_run,
        arguments = [ctx.executable._apphost_shimmer.path, apphost.path, dll.path],
        inputs = [apphost, dll],
        tools = [ctx.attr._apphost_shimmer.files],
        outputs = [output],
    )

    return output

def _create_launcher(ctx, runfiles, executable):
    runtime = ctx.toolchains["@rules_dotnet//dotnet/private:toolchain_type"].runtime
    launcher = ctx.actions.declare_file(paths.replace_extension(executable.basename, ".sh"), sibling = executable)
    ctx.actions.expand_template(
        template = ctx.file._launcher,
        output = launcher,
        substitutions = {
            "TEMPLATED_dotnet_root": runtime.files_to_run.executable.dirname,
            "TEMPLATED_executable": executable.short_path,
        },
        is_executable = True,
    )
    runfiles.append(ctx.file._bash_runfiles)
    if is_windows(ctx):
        runfiles.append(launcher)
        return create_windows_native_launcher_script(ctx, launcher)
    else:
        return launcher

def _symlink_manifest_loader(ctx, executable):
    loader = ctx.actions.declare_file("ManifestLoader.dll", sibling = executable)
    ctx.actions.symlink(output = loader, target_file = GetDotnetAssemblyInfoFromLabel(ctx.attr._manifest_loader).out)
    return loader

# TODO: Add docs
def build_binary(ctx, compile_action):
    providers = {}

    stdrefs = [ctx.attr._stdrefs] if ctx.attr.include_stdrefs else []

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

        providers[tfm] = compile_action(ctx, tfm, stdrefs, runtimeconfig, depsjson)

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
        executable = _create_launcher(ctx, direct_runfiles, executable)

    # TODO: Should we have separate flags for a standalone deployment and not?
    result.append(DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(
            files = direct_runfiles,
            transitive_files = result[0].transitive_runfiles,
        ).merge(ctx.toolchains["@rules_dotnet//dotnet/private:toolchain_type"].runtime[DefaultInfo].default_runfiles),
        files = depset(files),
    ))

    return result
