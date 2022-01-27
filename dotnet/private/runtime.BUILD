load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_dotnet//dotnet:defs.bzl", "dotnet_wrapper")

exports_files(
    glob(
        [
            "dotnet",
            "dotnet.exe",  # windows, yeesh
        ],
        allow_empty = True,
    ) + glob([
        "host/**/*",
        "shared/**/*",
    ]) +
    # csharp compiler: csc
    glob([
        "sdk/**/Roslyn/bincore/**/*",
    ]),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "apphost",
    srcs = glob([
        "sdk/**/AppHostTemplate/apphost.exe",
        "sdk/**/AppHostTemplate/apphost",
    ]),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "fsc_binary",
    # We glob both fsc.dll and fsc.exe for backwards compatibility
    # Pre .Net 5.0 the file was called fsc.exe but has been changed to fsc.dll
    srcs = glob([
        "sdk/**/FSharp/fsc.dll*",
        "sdk/**/FSharp/fsc.exe*",
    ]),
    visibility = ["//visibility:public"],
)

cc_binary(
    name = "dotnetw",
    srcs = [":main-cc"],
    data = glob(
        [
            "dotnet",
            "dotnet.exe",
        ],
        allow_empty = True,
    ),
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/cpp/runfiles"],
)

dotnet_wrapper(
    name = "main-cc",
    dotnet = glob(
        [
            "dotnet",
            "dotnet.exe",
        ],
        allow_empty = True,
    ),
)
