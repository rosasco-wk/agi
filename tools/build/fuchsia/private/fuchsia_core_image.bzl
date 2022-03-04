# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule for providing a pavable Fuchsia image from an in-tree build."""

load(":providers.bzl", "FuchsiaCoreImageInfo")

def _fuchsia_core_image_impl(ctx):
    return [
        FuchsiaCoreImageInfo(
            esp_blk = ctx.file.esp_blk,
            kernel_zbi = ctx.file.kernel_zbi,
            vbmetar = ctx.file.zedboot_vbmeta,
            zirconr = ctx.file.zedboot_zbi,
        ),
    ]

fuchsia_core_image = rule(
    doc = """Image files propogated from an in-tree build.

Users should not instantiate instances of this rule, this is used by the
fuchsia_product_repository workspace rule.
""",
    implementation = _fuchsia_core_image_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    attrs = {
        "zedboot_zbi": attr.label(
            mandatory = True,
            doc = "The ZBI for the Zedboot image used for paving.",
            allow_single_file = True,
        ),
        "zedboot_vbmeta": attr.label(
            mandatory = True,
            doc = "The vbmeta file for validating the Zedboot image.",
            allow_single_file = True,
        ),
        "esp_blk": attr.label(
            mandatory = True,
            doc = "EFI system partition image.",
            allow_single_file = True,
        ),
        "kernel_zbi": attr.label(
            mandatory = True,
            doc = "Zircon kernel image.",
            allow_single_file = True,
        ),
    },
)
