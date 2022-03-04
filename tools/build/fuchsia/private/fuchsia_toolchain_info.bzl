# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule for defining a Fuchsia toolchain."""

def _fuchsia_toolchain_info_impl(ctx):
    return [platform_common.ToolchainInfo(
        name = ctx.label.name,
        bootserver = ctx.executable.bootserver,
        blobfs = ctx.executable.blobfs,
        bindc = ctx.executable.bindc or None,
        cmc = ctx.executable.cmc,
        far = ctx.executable.far,
        ffx = ctx.executable.ffx,
        fidlc = ctx.executable.fidlc,
        fidlgen = ctx.executable.fidlgen,
        fidlgen_banjo = ctx.executable.fidlgen_banjo or None,
        fidlgen_llcpp = ctx.executable.fidlgen_llcpp or None,
        fvm = ctx.executable.fvm,
        merkleroot = ctx.executable.merkleroot,
        pm = ctx.executable.pm,
        zbi = ctx.executable.zbi,
    )]

fuchsia_toolchain_info = rule(
    implementation = _fuchsia_toolchain_info_impl,
    doc = """
Fuchsia toolchain info rule, to be passed to the native `toolchain` rule.

It provides information about tools in the Fuchsia toolchain, primarily those
included in the Fuchsia IDK.
""",
    attrs = {
        "bootserver": attr.label(
            doc = "bootserver executable",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "blobfs": attr.label(
            doc = "blobfs tool executable.",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "bindc": attr.label(
            doc = "bindc tool executable.",
            mandatory = False,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "cmc": attr.label(
            doc = "cmc tool executable.",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "far": attr.label(
            doc = "far tool executable.",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "ffx": attr.label(
            doc = "ffx tool executable.",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "fidlc": attr.label(
            doc = "fidlc tool executable.",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "fidlgen": attr.label(
            doc = "fidlgen tool executable.",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "fidlgen_banjo": attr.label(
            doc = "fidlgen_banjo tool executable.",
            mandatory = False,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "fidlgen_llcpp": attr.label(
            doc = "fidlgen_llcpp tool executable.",
            mandatory = False,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "fvm": attr.label(
            doc = "fvm tool executable.",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "merkleroot": attr.label(
            doc = "merkleroot tool executable.",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "pm": attr.label(
            doc = "pm tool executable.",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "zbi": attr.label(
            doc = "zbi tool executable.",
            mandatory = True,
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
    },
    provides = [platform_common.ToolchainInfo],
)
