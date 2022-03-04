# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule for declaring a board configuration for a Fuchsia product."""

load(
    ":providers.bzl",
    "FuchsiaAssemblyConfigInfo",
    "FuchsiaCoreImageInfo",
)

def _fuchsia_board_configuration_impl(ctx):
    config = ctx.actions.declare_file(ctx.label.name + ".json")
    sub = {}
    files = []
    for target in ctx.attr.files:
        f = target.files.to_list()[0]
        sub[ctx.attr.files[target]] = f.path
        files.append(f)

    fuchsia_core = ctx.attr.fuchsia_core[FuchsiaCoreImageInfo]
    sub["fuchsia.esp.blk"] = fuchsia_core.esp_blk.path
    sub["zedboot.zbi"] = fuchsia_core.zirconr.path
    sub["zedboot.vbmeta"] = fuchsia_core.vbmetar.path

    files.extend([
        fuchsia_core.esp_blk,
        fuchsia_core.zirconr,
        fuchsia_core.vbmetar,
    ])

    substitutions = {}
    for k in sub:
        substitutions["${" + k + "}"] = sub[k]

    ctx.actions.expand_template(
        template = ctx.file.template,
        output = config,
        substitutions = substitutions,
    )
    return [
        DefaultInfo(files = depset(direct = [config] + files)),
        FuchsiaAssemblyConfigInfo(config = config, package_manifests = [], blobs = []),
        fuchsia_core,
    ]

fuchsia_board_configuration = rule(
    doc = "Declares a board configuration JSON file for use with ffx assembly.",
    implementation = _fuchsia_board_configuration_impl,
    provides = [FuchsiaAssemblyConfigInfo, FuchsiaCoreImageInfo],
    attrs = {
        "template": attr.label(
            doc = "A template for a board configuration",
            allow_single_file = [".json"],
            mandatory = True,
        ),
        "files": attr.label_keyed_string_dict(
            doc = "A dictionary of files to template-literal keys",
            allow_files = True,
        ),
        "fuchsia_core": attr.label(
            mandatory = True,
            doc = "Core image to provide board files.",
            providers = [FuchsiaCoreImageInfo],
        ),
    },
)
