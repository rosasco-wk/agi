# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines a rule for a tool that creates an artifact_lock.json file."""

_RULE_SRC = """
#!/bin/bash
{update_tool} \
  --far-tool {far_tool} \
  --spec-file {spec_file} \
  --output-file $BUILD_WORKSPACE_DIRECTORY/{out_path}
"""

def _artifact_lock_updater_impl(ctx):
    sdk = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"]
    script = ctx.actions.declare_file(ctx.label.name)
    content = _RULE_SRC.format(
        update_tool = ctx.executable._update_tool.short_path,
        spec_file = ctx.file.spec_file.short_path,
        far_tool = sdk.far.short_path,
        out_path = ctx.attr.out_path,
    )
    ctx.actions.write(
        output = script,
        content = content,
        is_executable = True,
    )
    runfiles = ctx.runfiles(
        files = [
            ctx.executable._update_tool,
            ctx.file.spec_file,
            sdk.far,
        ],
    )
    runfiles = runfiles.merge(ctx.attr._update_tool[DefaultInfo].default_runfiles)
    return [DefaultInfo(
        executable = script,
        runfiles = runfiles,
    )]

artifact_lock_updater = rule(
    doc = "Outputs a tool that writes a lock-file to out_path in the current WORKSPACE",
    implementation = _artifact_lock_updater_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    executable = True,
    attrs = {
        "out_path": attr.string(
            doc = "Path for artifact_lock.json, relative to WORKSPACE",
            default = "artifact_lock.json",
        ),
        "spec_file": attr.label(
            doc = "Source artifact_spec.json file",
            mandatory = True,
            allow_single_file = [".json"],
        ),
        "_update_tool": attr.label(
            default = "@rules_fuchsia//tools/artifact:update",
            cfg = "host",
            executable = True,
        ),
    },
)
