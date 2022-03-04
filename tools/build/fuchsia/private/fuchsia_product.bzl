# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule for defining a Fuchsia product."""

load(":providers.bzl", "FuchsiaProductAssemblyBundleInfo")

_doc = """
fuchsia_product defines a Fuchsia product based on a product assembly bundle and
provided arguments.

This rule utilizes `ffx assembly product`, which is in development, and does not yet
perform a complete assembly, but generates an assembly configuration.
"""

def _fuchsia_product_impl(ctx):
    ffx_tool = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"].ffx
    bundle = ctx.attr.platform_bundle[FuchsiaProductAssemblyBundleInfo]

    config_file = ctx.actions.declare_file(ctx.label.name + "_config.json")
    ctx.actions.write(config_file, json.encode_indent({
        "build_type": ctx.attr.build_type,
    }))

    inputs = [config_file] + bundle.files + ctx.files._sdk_files
    out_dir = ctx.actions.declare_directory(ctx.label.name + "_out")
    outputs = [out_dir]
    ctx.actions.run(
        inputs = inputs,
        outputs = outputs,
        env = {
            "FFX_LOG_ENABLED": "false",
        },
        executable = ffx_tool,
        arguments = [
            "--config",
            "sdk.root=" + ctx.file._sdk_readme.dirname,
            "assembly",
            "product",
            "--outdir",
            out_dir.path,
            "--input-bundles-dir",
            bundle.root.dirname,
            "--product",
            config_file.path,
        ],
    )
    return [DefaultInfo(files = depset(direct = outputs))]

fuchsia_product = rule(
    implementation = _fuchsia_product_impl,
    toolchains = ["//fuchsia:toolchain"],
    doc = _doc,
    attrs = {
        "build_type": attr.string(
            doc = "Platform build type to use for the resulting product.",
            default = "eng",
        ),
        "legacy_bundle": attr.label(
            doc = "A fuchsia_product_assembly_bundle target.",
            providers = [FuchsiaProductAssemblyBundleInfo],
            mandatory = True,
        ),
        "_sdk_files": attr.label(
            allow_files = True,
            default = "@fuchsia_sdk//:all_files",
        ),
        # This is to get a file known to be at the root of the SDK, so that
        # the SDK path can be provided to FFX.
        "_sdk_readme": attr.label(
            allow_single_file = True,
            default = "@fuchsia_sdk//:README.md",
        ),
        "_sdk_manifest": attr.label(
            allow_single_file = True,
            default = "@fuchsia_sdk//:meta/manifest.json",
        ),
    },
)
