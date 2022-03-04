# Copyright 2022 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule for declaring a FIDL library"""

load(":providers.bzl", "FuchsiaFidlLibraryInfo")

def _gather_dependencies(deps):
    info = []
    libs_added = []
    for dep in deps:
        for lib in dep[FuchsiaFidlLibraryInfo].info:
            name = lib.name
            if name in libs_added:
                continue
            libs_added.append(name)
            info.append(lib)
    return info

def _fidl_library_impl(context):
    sdk = context.toolchains["@rules_fuchsia//fuchsia:toolchain"]
    ir = context.outputs.ir
    tables = context.outputs.coding_tables
    library_name = context.attr.library

    info = _gather_dependencies(context.attr.deps)
    info.append(struct(
        name = library_name,
        files = context.files.srcs,
    ))

    files_argument = []
    inputs = []
    for lib in info:
        files_argument += ["--files"] + [f.path for f in lib.files]
        inputs.extend(lib.files)

    context.actions.run(
        executable = sdk.fidlc,
        arguments = [
            "--experimental",
            "new_syntax_only",
            "--json",
            ir.path,
            "--name",
            library_name,
            "--tables",
            tables.path,
        ] + files_argument,
        inputs = inputs,
        outputs = [
            ir,
            tables,
        ],
        mnemonic = "Fidlc",
    )

    return [
        # Exposing the coding tables here so that the target can be consumed as a
        # C++ source.
        DefaultInfo(files = depset([tables])),
        # Passing library info for dependent libraries.
        FuchsiaFidlLibraryInfo(info = info, name = library_name, ir = ir),
    ]

# A FIDL library.
#
# Parameters
#
#   library
#     Name of the FIDL library.
#
#   srcs
#     List of source files.
#
#   deps
#     List of labels for FIDL libraries this library depends on.
fuchsia_fidl_library = rule(
    implementation = _fidl_library_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    attrs = {
        "library": attr.string(
            doc = "The name of the FIDL library",
            mandatory = True,
        ),
        "srcs": attr.label_list(
            doc = "The list of .fidl source files",
            mandatory = True,
            allow_files = True,
            allow_empty = False,
        ),
        "deps": attr.label_list(
            doc = "The list of libraries this library depends on",
            mandatory = False,
            providers = [FuchsiaFidlLibraryInfo],
        ),
    },
    outputs = {
        # The intermediate representation of the library, to be consumed by bindings
        # generators.
        "ir": "%{name}_ir.json",
        # The C coding tables.
        "coding_tables": "%{name}_tables.c",
    },
)
