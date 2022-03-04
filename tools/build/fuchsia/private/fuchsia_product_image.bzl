# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule for defining a pavable Fuchsia image."""

load(
    ":providers.bzl",
    "FuchsiaAssemblyConfigInfo",
    "FuchsiaCoreImageInfo",
    "FuchsiaProductBuildInfo",
    "FuchsiaProductImageInfo",
)

# Base source for running ffx assembly. This is a shell script so that code
# copying the build artifacts to paths expected by Bazel can be appended.
_ASSEMBLY_RUNNER_SH = """
$FFX \
    --config "sdk.root=$SDK_ROOT,assembly_enabled=true" \
    assembly \
    image \
    --product $PRODUCT_PATH \
    --board $BOARD_PATH \
    --outdir $OUTDIR

"""

def _fuchsia_product_image_impl(ctx):
    ffx_tool = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"].ffx
    inputs = depset(
        direct = [ffx_tool],
        transitive = [
            ctx.attr.product.files,
            ctx.attr.board.files,
            ctx.attr._sdk_files.files,
        ],
    )
    product_config_info = ctx.attr.product[FuchsiaAssemblyConfigInfo]
    config_file = product_config_info.config
    board_config_info = ctx.attr.board[FuchsiaAssemblyConfigInfo]
    board_config_file = board_config_info.config

    blob_blk = ctx.actions.declare_file(ctx.label.name + "_data.blk")
    data_blk = ctx.actions.declare_file(ctx.label.name + "_blob.blk")
    fvm_sparse_blk = ctx.actions.declare_file(ctx.label.name + "_fvm_sparse.blk")
    zircona = ctx.actions.declare_file(ctx.label.name + "_zircon.zbi")
    vbmetaa = ctx.actions.declare_file(ctx.label.name + "_zircon.vbmeta")
    images_json = ctx.actions.declare_file(ctx.label.name + "_images.json")
    update_manifest_json = ctx.actions.declare_file(ctx.label.name + "_update_package_manifest.json")
    base_manifest_json = ctx.actions.declare_file(ctx.label.name + "_base_package_manifest.json")

    # Files that appear in the out directory from ffx assembly, that
    # should be copied to targets declared by Bazel.
    src_map = {
        "fvm.sparse.blk": fvm_sparse_blk,
        "blob.blk": blob_blk,
        "data.blk": data_blk,
        "fuchsia.zbi": zircona,
        "fuchsia.vbmeta": vbmetaa,
        "images.json": images_json,
        "update_package_manifest.json": update_manifest_json,
        "base_package_manifest.json": base_manifest_json,
    }

    # Appends shell commands that copy the files in src_map to the paths
    # generated by Bazel.
    shell_src = _ASSEMBLY_RUNNER_SH
    for k in src_map:
        shell_src += "cp $OUTDIR/{} {}\n".format(k, src_map[k].path)

    out_dir = ctx.actions.declare_directory(ctx.label.name + "_out")
    out_files = src_map.values()
    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [out_dir] + out_files,
        command = shell_src,
        env = {
            "BOARD_PATH": board_config_file.path,
            "OUTDIR": out_dir.path,
            "FFX": ffx_tool.path,
            "FFX_LOG_ENABLED": "false",
            "PRODUCT_PATH": config_file.path,
            "SDK_ROOT": ctx.file._sdk_readme.dirname,
        },
        progress_message = "Assembling images for %s" % ctx.label.name,
    )

    fuchsia_core = ctx.attr.board[FuchsiaCoreImageInfo]
    return [
        DefaultInfo(files = depset(direct = out_files)),
        FuchsiaProductImageInfo(
            blob_blk = blob_blk,
            data_blk = data_blk,
            esp_blk = fuchsia_core.esp_blk,
            images_json = images_json,
            kernel_zbi = fuchsia_core.kernel_zbi,
            vbmetaa = vbmetaa,
            vbmetar = fuchsia_core.vbmetar,
            zircona = zircona,
            zirconr = fuchsia_core.zirconr,
        ),
        product_config_info,
        FuchsiaProductBuildInfo(
            board = board_config_file,
            manifest = ctx.file._sdk_manifest,
            update_manifest = update_manifest_json,
            base_manifest = base_manifest_json,
        ),
    ]

fuchsia_product_image = rule(
    doc = """Declares a Fuchsia product image.

`product` must be a `fuchsia_product_configuration` target.
`board` must be a `fuchsia_board_configuration` target.

fuchsia_product_image targets may be used by the `fuchsia_product_pave` rule.

This generates the following files:

name_data.blk - the MinFS partition.
name_blob.blk - the BlobFS partition.
name_fvm_sparse.blk - the FVM sparse image.
name_fuchsia.zbi - the Zircon boot image.
name_fuchsia.vbmeta - VBMeta signature for the Zircon boot image.
""",
    implementation = _fuchsia_product_image_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    provides = [FuchsiaProductImageInfo, FuchsiaAssemblyConfigInfo, FuchsiaProductBuildInfo],
    attrs = {
        "product": attr.label(
            doc = "A fuchsia_product_configuration target.",
            providers = [FuchsiaAssemblyConfigInfo],
        ),
        "board": attr.label(
            doc = "A fuchsia_board_configuration target.",
            providers = [FuchsiaAssemblyConfigInfo, FuchsiaCoreImageInfo],
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
