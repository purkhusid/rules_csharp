"""
Rules for compiling C# binaries.
"""

load("//dotnet/private:rules/csharp/binary_private.bzl", "csharp_binary_private")

def csharp_binary(**kwargs):
    csharp_binary_private(**kwargs)
