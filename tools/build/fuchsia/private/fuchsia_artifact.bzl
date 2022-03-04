# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule for defining a Fuchsia PDK artifact."""

load(":providers.bzl", "FuchsiaArtifactInfo")

def _create_blob_manifest(ctx):
    sdk = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"]

    blobs = [ctx.file.file] + ctx.files.blobs

    blob_path_list = [blob.path for blob in blobs]
    blob_path_list_file_contents = "\n".join(blob_path_list)
    blob_path_list_file = ctx.actions.declare_file(ctx.label.name + "_blob_list")
    ctx.actions.write(blob_path_list_file, blob_path_list_file_contents)

    blob_manifest = ctx.actions.declare_file(ctx.label.name + "_blob_manifest")
    ctx.actions.run(
        outputs = [blob_manifest],
        inputs = [blob_path_list_file, sdk.merkleroot, ctx.file.file] + ctx.files.blobs,
        executable = ctx.executable._blob_manifest_creator,
        arguments = [
            "--merkleroot_tool",
            sdk.merkleroot.path,
            "--input",
            blob_path_list_file.path,
            "--output",
            blob_manifest.path,
        ],
    )

    return blob_manifest

def _create_package_manifest(ctx, blob_manifest):
    sdk = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"]

    package_manifest = ctx.actions.declare_file(ctx.label.name + "_package_manifest.json")
    ctx.actions.run(
        outputs = [package_manifest],
        inputs = [sdk.far, blob_manifest, ctx.file.file] + ctx.files.blobs,
        executable = ctx.executable._package_manifest_creator,
        arguments = [
            "--far-tool",
            sdk.far.path,
            "--meta-far-file",
            ctx.file.file.path,
            "--blob-manifest",
            blob_manifest.path,
            "--output-file",
            package_manifest.path,
        ],
    )

    return package_manifest

def _fuchsia_artifact_impl(ctx):
    attributes = dict(ctx.attr.attributes)
    name = ctx.label.name
    if ctx.attr.artifact_name:
        name = ctx.attr.artifact_name

    blob_manifest = _create_blob_manifest(ctx)

    package_manifest = None
    if ctx.attr.type == "package":
        package_manifest = _create_package_manifest(ctx, blob_manifest)

    return [FuchsiaArtifactInfo(
        attributes = attributes,
        blobs = ctx.files.blobs + [ctx.file.file],
        blob_manifest = blob_manifest,
        file = ctx.file.file,
        name = name,
        package_manifest = package_manifest,
        type = ctx.attr.type,
    )]

fuchsia_artifact = rule(
    doc = "A pre-built artifact used for product assembly.",
    implementation = _fuchsia_artifact_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    provides = [FuchsiaArtifactInfo],
    attrs = {
        "artifact_name": attr.string(
            doc = "The group-unique name of the artifact. If omitted, the target name is used",
        ),
        "attributes": attr.string_dict(
            doc = """
String attributes for this artifact. The \"name\" attribute is set to the name
of the target if it is not specified here.
""",
        ),
        "blobs": attr.label_list(
            doc = "All blobs required by this artifact.",
            allow_files = True,
        ),
        "file": attr.label(
            doc = """
The artifact file itself. For type \"package\", this is a meta.far file.
""",
            allow_single_file = True,
            mandatory = True,
        ),
        "type": attr.string(
            doc = "The artifact type. Currently can only be \"package\"",
            default = "package",
            values = ["package"],
        ),
        "_blob_manifest_creator": attr.label(
            default = "@rules_fuchsia//tools:blob_manifest_creator",
            executable = True,
            cfg = "exec",
        ),
        "_package_manifest_creator": attr.label(
            default = "@rules_fuchsia//tools:package_manifest_creator",
            executable = True,
            cfg = "exec",
        ),
    },
)
