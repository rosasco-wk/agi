# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit test Fuchsia packages."""

def _banjo_cc_codegen_impl(context):
    sdk = context.toolchains["@rules_fuchsia//fuchsia:toolchain"]
    ir = context.attr.library[FuchsiaFidlLibraryInfo].ir
    name = context.attr.library[FuchsiaFidlLibraryInfo].name

    base_path = context.attr.name + ".banjo"

    stem = base_path + "/" + name.replace(".", "/") + "/cpp/banjo"
    header = context.actions.declare_file(stem + ".h")

    c_stem = base_path + "/" + name.replace(".", "/") + "/c/banjo"
    c_header = context.actions.declare_file(c_stem + ".h")

    cci_header = context.actions.declare_file("banjo-internal.h", sibling = header)

    run_args = [
        ("cpp", header, header.dirname + "/banjo.h"),
        ("c", c_header, c_header.dirname + "/banjo.h"),
        ("cpp_internal", cci_header, cci_header.dirname + "/banjo-internal.h"),
    ]

    for (backend, header_type, output) in run_args:
        context.actions.run(
            executable = sdk.fidlgen_banjo,
            arguments = [
                "--ir",
                ir.path,
                "--output",
                output,
                "--backend",
                backend,
            ],
            inputs = [
                ir,
            ],
            outputs = [
                header_type,
            ],
            mnemonic = "Banjo",
        )
    return [
        DefaultInfo(files = depset([header, c_header, cci_header])),
    ]

# Runs fidlgen to produce the header files.
_banjo_cc_codegen = rule(
    implementation = _banjo_cc_codegen_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    # Files must be generated in genfiles in order for the header to be included
    # anywhere.
    output_to_genfiles = True,
    attrs = {
        "library": attr.label(
            doc = "The Banjo FIDL library to generate code for",
            mandatory = True,
            allow_files = False,
            providers = [FuchsiaFidlLibraryInfo],
        ),
    },
)

def fuchsia_unittest_package(name, package_name, unit_tests, **kwargs):
    """Generates Fuchsia packages with unit tests.

    Args:
      name: Target name. Required.
      package_name: Package name. If not specified, will be the same as the target name.
      unit_tests: Unit tests to be packaged. Required.
      **kwargs: Remaining args.
    """


    for test in unit_tests:
        # TODO: for each unit_test: create fuchsia_component_manifest

        fuchsia_component_manifest(
            name = "_" + target + "_" + test,
            src =

        )


    # TODO: for each unit_test: create fuchsia_unittest_component
    # TODO: create a fuchsia_package
    _banjo_cc_codegen(
        name = gen_name,
        library = library,
    )

    native.cc_library(
        tags = tags,
        name = name,
        hdrs = [
            ":%s" % gen_name,
        ],
        srcs = [],
        includes = [
            # This is necessary in order to locate generated headers.
            gen_name + ".banjo",
        ],
        deps = deps,
        **kwargs
    )
