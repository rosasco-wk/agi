# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule for an action that paves a Fuchsia image to a device"""

load(":providers.bzl", "FuchsiaProductImageInfo")

_boot_command_template = """\
#!/bin/bash

{bootserver} \
    -w 10 \
    --board_name x64 \
    --bootloader "{bootloader}" \
    --boot "{zircona}" \
    --fvm "{fvm}" \
    --vbmetaa "{vbmetaa}" \
    --vbmetar "{vbmetar}" \
    --zircona "{zircona}" \
    --zirconr "{zirconr}" \
    "$@"
"""

def _fuchsia_image_paver_impl(ctx):
    sdk = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"]
    image_info = ctx.attr.product_image[FuchsiaProductImageInfo]
    fvm_sparse = ctx.actions.declare_file(ctx.label.name + "_fvm.sparse.blk")
    ctx.actions.run(
        outputs = [fvm_sparse],
        inputs = [
            sdk.fvm,
            image_info.blob_blk,
            image_info.data_blk,
        ],
        executable = sdk.fvm,
        arguments = [
            fvm_sparse.path,
            "sparse",
            "--slice",
            str(ctx.attr.slice_size),
            "--blob",
            image_info.blob_blk.path,
            "--data",
            image_info.data_blk.path,
        ],
    )

    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    script_content = _boot_command_template.format(
        bootserver = sdk.bootserver.short_path,
        bootloader = image_info.esp_blk.short_path,
        fvm = fvm_sparse.short_path,
        vbmetaa = image_info.vbmetaa.short_path,
        vbmetar = image_info.vbmetar.short_path,
        zircona = image_info.zircona.short_path,
        zirconr = image_info.zirconr.short_path,
    )
    ctx.actions.write(script, script_content, is_executable = True)

    runfiles = ctx.runfiles(
        files = [
            sdk.bootserver,
            image_info.esp_blk,
            fvm_sparse,
            image_info.vbmetaa,
            image_info.vbmetar,
            image_info.zircona,
            image_info.zirconr,
        ],
    )
    return [
        DefaultInfo(executable = script, runfiles = runfiles),
    ]

fuchsia_image_paver = rule(
    doc = """Declares an action that paves the given product.

Additional command line arguments are passed to the IDK bootserver tool.
""",
    implementation = _fuchsia_image_paver_impl,
    executable = True,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    attrs = {
        "product_image": attr.label(
            mandatory = True,
            doc = "A fuchsia_product_image target.",
            providers = [FuchsiaProductImageInfo],
        ),
        "slice_size": attr.int(
            default = 8388608,
            doc = "FVM slice size in bytes",
        ),
    },
)
