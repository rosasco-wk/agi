# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule to publish artifact_group.json to TUF repository and blobs to Blobs Server.

Sample usage:
```
fuchsia_artifact_release(
    name = "test_artifact_release",
    artifact = "<label of your artifact>",
    gcs_bucket = "discover-cloud.appspot.com",
    repo_hostname = "e20c92ac-1c24-4052-8ff9-8aaa31a0f820.fuchsia-updates.googleusercontent.com",
    artifact_list_file = "@//:artifact_list.json",
)
```

"""

load(
    ":providers.bzl",
    "AccessTokenInfo",
    "FuchsiaArtifactInfo",
    "FuchsiaVersionInfo",
)

_UPLOAD_SH = """
$DPI \
    upload \
    $REPO_HOSTNAME \
    $ARTIFACT_GROUP_PATH \
    $BLOB_DIRECTORY_PATH \
    $ACCESS_TOKEN \
    $GCS_BUCKET
"""

def _fuchsia_product_release_impl(ctx):
    merkleroot_tool = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"].merkleroot
    artifact = ctx.attr.artifact[FuchsiaArtifactInfo]

    # Generate the artifact_groups.json
    artifact_groups_file = ctx.actions.declare_file(ctx.label.name + "_artifact_groups.json")
    args = ctx.actions.args()
    args.add("--artifact-list-file", ctx.file.artifact_list_file.path)
    args.add("--artifact-groups-url", ctx.attr.repo_hostname)
    args.add("--publisher", "dummy")
    args.add("--version", ctx.attr._version[FuchsiaVersionInfo].version)
    args.add("--merkleroot-tool", merkleroot_tool.path)
    args.add("--output-file", artifact_groups_file.path)

    ctx.actions.run(
        outputs = [artifact_groups_file],
        executable = ctx.executable._artifact_group_creator,
        arguments = [args],
    )

    output_files = [artifact_groups_file]

    # Copy blobs to a directory
    blob_directory = ctx.actions.declare_directory(ctx.label.name + "_blobs")
    output_files += [blob_directory]
    shell_src = "cp "
    for blob in artifact.blobs:
        shell_src += blob.path + " "
    shell_src += artifact_groups_file.path + " "
    shell_src += blob_directory.path + "\n"

    shell_src += _UPLOAD_SH

    ctx.actions.run_shell(
        inputs = artifact.blobs + [artifact_groups_file],
        outputs = [blob_directory],
        command = shell_src,
        env = {
            "DPI": ctx.file._dpi_tool.path,
            "REPO_HOSTNAME": ctx.attr.repo_hostname,
            "ARTIFACT_GROUP_PATH": artifact_groups_file.path,
            "BLOB_DIRECTORY_PATH": blob_directory.path,
            "ACCESS_TOKEN": ctx.attr._access_token[AccessTokenInfo].token,
            "USER": "dummy",
            "GCS_BUCKET": ctx.attr.gcs_bucket,
        },
        progress_message = "Upload files for %s" % ctx.label.name,
    )

    return [
        DefaultInfo(files = depset(direct = output_files)),
    ]

fuchsia_artifact_release = rule(
    doc = "Declares a release archive.",
    implementation = _fuchsia_product_release_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    attrs = {
        "artifact": attr.label(
            mandatory = True,
            doc = "Artifact to upload.",
            providers = [FuchsiaArtifactInfo],
        ),
        "artifact_list_file": attr.label(
            doc = "The file list all the artifacts along with the attributes",
            allow_single_file = [".json"],
            mandatory = True,
        ),
        "gcs_bucket": attr.string(
            mandatory = True,
            doc = "The GCS bucket which is used as staging aread.",
        ),
        "repo_hostname": attr.string(
            mandatory = True,
            doc = "The MOS repository where the artifacts are uploaded to",
        ),
        "_access_token": attr.label(
            doc = "The access token used to upload to MOS repository.",
            default = ":access_token",
        ),
        "_version": attr.label(
            doc = "The version number that overwrites the sdk version.",
            default = ":build_version",
        ),
        "_dpi_tool": attr.label(
            allow_single_file = True,
            default = "@dpi_tool//file",
        ),
        "_artifact_group_creator": attr.label(
            executable = True,
            cfg = "exec",
            default = "//tools/gcs_upload:artifact_group_builder",
        ),
    },
)
