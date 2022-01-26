"""
Rules to configure the .NET toolchain of rules_dotnet.
"""

load(":sdk.bzl", "DOTNET_SDK_VERSION")

def _dotnet_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            runtime = ctx.attr.runtime.files_to_run,
            csharp_compiler = ctx.file.csharp_compiler,
            fsharp_compiler = ctx.file.fsharp_compiler,
        ),
    ]

dotnet_toolchain = rule(
    _dotnet_toolchain_impl,
    attrs = {
        "runtime": attr.label(
            executable = True,
            allow_single_file = True,
            mandatory = True,
            cfg = "exec",
        ),
        "csharp_compiler": attr.label(
            executable = True,
            allow_single_file = True,
            mandatory = True,
            cfg = "exec",
        ),
        "fsharp_compiler": attr.label(
            executable = True,
            allow_single_file = True,
            mandatory = True,
            cfg = "exec",
        ),
    },
)

# This is called in BUILD
# buildifier: disable=unnamed-macro
def configure_toolchain(os, exe = "dotnetw"):
    dotnet_toolchain(
        name = "dotnet_x86_64-" + os,
        runtime = "@netcore-sdk-%s//:%s" % (os, exe),
        csharp_compiler = "@netcore-sdk-%s//:sdk/%s/Roslyn/bincore/csc.dll" % (os, DOTNET_SDK_VERSION),
        fsharp_compiler = "@netcore-sdk-%s//:fsc_binary" % (os),
    )

    native.toolchain(
        name = "dotnet_%s_toolchain" % os,
        exec_compatible_with = [
            "@platforms//os:" + os,
            "@platforms//cpu:x86_64",
        ],
        toolchain = "dotnet_x86_64-" + os,
        toolchain_type = ":toolchain_type",
    )
