# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines WORKSPACE rule for loading an external Fuchsia product."""

_BLOB_SERVER = "fuchsia-blobs.googleusercontent.com"

_WORKSPACE_CHECKSUM_UPDATER_SRC = """
#!/bin/bash
cp $SRC $BUILD_WORKSPACE_DIRECTORY/$1
"""

_FUCHSIA_ARTIFACT_TEMPLATE = """
fuchsia_artifact(
    name = "{target_name}",
    artifact_name = "{artifact_name}",
    attributes = {{{attributes}}},
    blobs = [
        {blobs}
    ],
    file = "{artifact_label}",
    type = "{artifact_type}",
    visibility = ["//visibility:public"],
)
"""

_FUCHSIA_CORE_TEMPLATE = """
fuchsia_core_image(
    name = "fuchsia_core",
    esp_blk = ":${fuchsia.esp.blk}",
    kernel_zbi = ":${kernel.zbi}",
    visibility = ["//visibility:public"],
    zedboot_vbmeta = ":${zedboot.vbmeta}",
    zedboot_zbi = ":${zedboot.zbi}",
)
"""

_FUCHSIA_ASSEMBLY_BUNDLE_BUILD = """
filegroup(
    name = "all_content",
    srcs = glob(["legacy/**"], exclude = [
      "WORKSPACE",
      "BUILD.bazel",
    ]),
)

assembly_bundle(
    name = "assembly_bundle",
    root = ":root",
    files = ":all_content",
    visibility = ["//visibility:public"],
)
"""

def _dedupe_sequence(v):
    d = dict()
    for el in v:
        d[el] = True
    return d.keys()

def _get_repo_tool(ctx, tool):
    base = "@" + ctx.attr.sdk_repository_name + "//:tools/x64/"
    return str(ctx.path(Label(base + tool)))

def _get_artifact_target_name(artifact):
    return artifact["name"].split("/")[0] + "_artifact"

def _get_artifact_contents(ctx, artifact_path):
    result = ctx.execute([
        _get_repo_tool(ctx, "far"),
        "cat",
        "--archive=" + artifact_path,
        "--file=meta/contents",
    ])
    if result.return_code:
        fail("Could not extract '" + artifact_path + "': " + result.stderr)
    files = dict()
    for line in result.stdout.splitlines():
        pair = line.split("=")
        files[pair[0]] = pair[1]
    return files

def _create_core_image_definition(ctx, contents):
    out = _FUCHSIA_CORE_TEMPLATE
    for (k, v) in contents.items():
        out = out.replace("${" + k + "}", v)
    return out

def _create_fuchsia_artifact_definition(ctx, artifact):
    artifact_path = str(ctx.path(artifact["merkle"]))
    attributes = ""
    for k, v in artifact["attributes"].items():
        attributes += "\n        \"{}\": \"{}\",".format(k, v)
    if len(attributes) > 0:
        attributes += "\n    "
    blobs = [
        "\":" + blob + "\","
        for blob in _dedupe_sequence(artifact["blobs"])
        if blob != artifact["merkle"]
    ]
    blobs = "\n        ".join(blobs)
    artifact_type = "package"
    if "type" in artifact:
        artifact_type = artifact["type"]

    out = _FUCHSIA_ARTIFACT_TEMPLATE.format(
        target_name = _get_artifact_target_name(artifact),
        artifact_label = ":" + artifact["merkle"],
        artifact_name = artifact["name"],
        artifact_type = artifact_type,
        attributes = attributes,
        blobs = blobs,
    )

    if artifact["name"] == "fuchsia_core/0":
        contents = _get_artifact_contents(ctx, artifact_path)
        out += _create_core_image_definition(ctx, contents)

    return out

def _create_file_definition(ctx, artifact):
    out = ""
    if artifact["name"] == "legacy.tgz":
        artifact_path = str(ctx.path(artifact["name"]))
        ctx.extract(artifact_path, output = "legacy")
        ctx.file("root")
        out += _FUCHSIA_ASSEMBLY_BUNDLE_BUILD
    return out

def _fetch_blob(ctx, checksum_dict, new_checksum_dict, merkle, filename):
    if ctx.path(merkle).exists:
        return
    sha256 = checksum_dict.get(merkle, "")
    result = ctx.download(
        url = "https://{}/{}".format(_BLOB_SERVER, merkle),
        output = ctx.path(filename),
        canonical_id = merkle,
        sha256 = sha256,
    )
    new_checksum_dict[merkle] = result.sha256

def _download_artifact(ctx, checksum_dict, new_checksum_dict, artifact):
    store_type = artifact["artifact_store"]["type"]
    if store_type != "tuf":
        ctx.fail("{} is not a supported artifact store type".format(store_type))

    if artifact["type"] == "file":
        _fetch_blob(ctx, checksum_dict, new_checksum_dict, artifact["merkle"], artifact["name"])
    elif artifact["type"] == "package":
        _fetch_blob(ctx, checksum_dict, new_checksum_dict, artifact["merkle"], artifact["merkle"])
    else:
        fail("Artifact type " + artifact["type"] + " not supported")

    if "blobs" in artifact:
        for blob in artifact["blobs"]:
            _fetch_blob(ctx, checksum_dict, new_checksum_dict, blob, blob)

def _fuchsia_product_repository_impl(ctx):
    checksum_path = ctx.path(ctx.attr.lock_file).dirname.get_child(ctx.attr.checksum_file)
    checksum_dict = {}
    new_checksum_dict = {}
    if checksum_path.exists:
        checksum_dict = json.decode(ctx.read(checksum_path))

    artifact_lock = json.decode(ctx.read(ctx.attr.lock_file))
    artifact_definitions = ""
    for artifact in artifact_lock["artifacts"]:
        _download_artifact(ctx, checksum_dict, new_checksum_dict, artifact)
        if artifact["type"] == "file":
            artifact_definitions += _create_file_definition(ctx, artifact)
        elif artifact["type"] == "package":
            artifact_definitions += _create_fuchsia_artifact_definition(ctx, artifact)
        else:
            fail("Artifact type " + artifact["type"] + " not supported")

    ctx.file(
        "checksum.json",
        content = json.encode_indent(
            new_checksum_dict,
            indent = "  ",
        ) + "\n",
        executable = False,
    )
    ctx.file("workspace_checksum_updater.sh", content = _WORKSPACE_CHECKSUM_UPDATER_SRC)

    ctx.template(
        "BUILD.bazel",
        ctx.attr._template,
        substitutions = {
            "{artifact_definitions}": artifact_definitions,
        },
    )

fuchsia_product_repository = repository_rule(
    doc = """
Fetch external artifacts from an artifact_lock.json file.

Each artifact is exported as a `fuchsia_artifact` target named after the
artifact in the lock file with `_artifact` appended.

If an artifact is named `fuchsia_core`, a `fuchsia_core` target is made
available that can be used anywhere a `fuchsia_product` target is expected.

A target is also exported named `workspace_checksum_updater` that creates a
checksum.json file in the current workspace. This allows Bazel to take
advantage of SHA256-addressed caching for artifact downloads. The file should
be included in the attributes of this rule, see `checksum_file`.

A lock file can be generated by running
@rules_fuchsia//fuchsia/tools/artifact:update on a spec file.

See the documentation in //fuchsia/tools/artifact/update.py for
more details.
""",
    implementation = _fuchsia_product_repository_impl,
    attrs = {
        "lock_file": attr.label(
            doc = "product version lock file",
            allow_single_file = [".json"],
            mandatory = True,
        ),
        "checksum_file": attr.string(
            doc = "File mapping blob merkle root to SHA256 checksum. Path relative to lock_file.",
            default = "checksum.json",
        ),
        "sdk_repository_name": attr.string(
            doc = "the name of an sdk_repository or local_fuchsia_repository target",
            mandatory = True,
        ),
        "_template": attr.label(
            default = "@rules_fuchsia//fuchsia/private:fuchsia_product_repository_template.BUILD",
            allow_single_file = True,
        ),
    },
)
