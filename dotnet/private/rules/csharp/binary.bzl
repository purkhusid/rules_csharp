"""
Rules for compiling C# binaries.
"""

load("//dotnet/private:rules/csharp/binary_private.bzl", "csharp_binary_private", "csharp_binary_private_without_shim")

def csharp_binary(**kwargs):
    csharp_binary_private(**kwargs)

def csharp_binary_without_shim(**kwargs):
    csharp_binary_private_without_shim(**kwargs)
