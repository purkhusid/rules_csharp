"""Public API surface is re-exported here.

Users should not load files under "/dotnet"
"""

load(
    "//dotnet/private:repositories.bzl",
    _dotnet_register_toolchains = "dotnet_register_toolchains",
    _dotnet_repositories = "dotnet_repositories",
)
load(
    "//dotnet/private:rules/csharp/binary.bzl",
    _csharp_binary = "csharp_binary",
)
load(
    "//dotnet/private:rules/wrapper.bzl",
    _dotnet_wrapper = "dotnet_wrapper",
)
load(
    "//dotnet/private:rules/csharp/library.bzl",
    _csharp_library = "csharp_library",
)
load(
    "//dotnet/private:rules/library_set.bzl",
    _library_set = "library_set",
)
load(
    "//dotnet/private:rules/csharp/nunit_test.bzl",
    _csharp_nunit_test = "csharp_nunit_test",
)
load(
    "//dotnet/private:rules/imports.bzl",
    _import_library = "import_library",
    _import_multiframework_library = "import_multiframework_library",
)
load(
    "//dotnet/private:macros/nuget.bzl",
    _import_nuget_package = "import_nuget_package",
    _nuget_package = "nuget_package",
)
load(
    "//dotnet/private:macros/setup_basic_nuget_package.bzl",
    _setup_basic_nuget_package = "setup_basic_nuget_package",
)

dotnet_wrapper = _dotnet_wrapper
csharp_binary = _csharp_binary
csharp_library = _csharp_library
library_set = _library_set
csharp_nunit_test = _csharp_nunit_test
dotnet_register_toolchains = _dotnet_register_toolchains
dotnet_repositories = _dotnet_repositories
import_multiframework_library = _import_multiframework_library
import_library = _import_library
import_nuget_package = _import_nuget_package
nuget_package = _nuget_package
setup_basic_nuget_package = _setup_basic_nuget_package
