# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines a WORKSPACE rule for loading a version of the Fuchsia IDK."""

load("//fuchsia/private/sdk_templates:generate_sdk_build_rules.bzl", "generate_sdk_build_rules")
load("//fuchsia/private:utils.bzl", "normalize_os")

# Base URL for Fuchsia IDK archives.
_SDK_URL_TEMPLATE = "https://chrome-infra-packages.appspot.com/dl/fuchsia/sdk/core/{os}-amd64/+/{tag}"

# Environment variable used to set a local SDK archive
_SDK_ARCHIVE_ENV_VAR = "BAZEL_FUCHSIA_SDK_ARCHIVE"

def _sdk_url(os, tag):
    # Return the URL of the SDK given an Operating System string and
    # a CIPD tag.
    return _SDK_URL_TEMPLATE.format(os = os, tag = tag)

def _instantiate_local(ctx):
    # Extracts the SDK from a local archive file.
    ctx.report_progress("Extracting local SDK archive")
    ctx.extract(archive = ctx.os.environ[_SDK_ARCHIVE_ENV_VAR])

def _fuchsia_sdk_repository_impl(ctx):
    ctx.file("WORKSPACE.bazel", content = "")
    normalized_os = normalize_os(ctx)
    if _SDK_ARCHIVE_ENV_VAR in ctx.os.environ:
        _instantiate_local(ctx)
    elif ctx.attr.cipd_tag:
        sha256 = ""
        if ctx.attr.sha256:
            sha256 = ctx.attr.sha256[normalized_os]
        ctx.download_and_extract(
            _sdk_url(normalized_os, ctx.attr.cipd_tag),
            type = "zip",
            sha256 = sha256,
        )
    elif ctx.attr.local_archive:
        _instantiate_local(ctx)
    else:
        fail("One of local_archive or cipd_tag must be set for fuchsia_sdk_repository")

    ctx.report_progress("Generating Bazel rules for the SDK")
    manifests = ["meta/manifest.json"]
    ddk_manifest = "meta/ddk_manifest.json"
    has_ddk_manifest = False
    if ctx.path(ddk_manifest).exists:
        manifests.append(ddk_manifest)
        has_ddk_manifest = True

    ctx.template(
        "BUILD.bazel",
        ctx.attr._template,
        substitutions = {
            "{{has_ddk}}": "has_ddk" if has_ddk_manifest else "no_ddk",
        },
    )

    generate_sdk_build_rules(ctx, manifests)

fuchsia_sdk_repository = repository_rule(
    doc = """
Loads a particular version of the Fuchsia IDK.

The environment variable BAZEL_FUCHSIA_SDK_ARCHIVE can optionally be set
to the path of a locally built SDK archive file to override the tag
parameter.

If cipd_tag is set, sha256 can optionally be set to verify the downloaded file and to
allow Bazel to cache the file.

If cipd_tag is not set, BAZEL_FUCHSIA_SDK_ARCHIVE must be set.
""",
    implementation = _fuchsia_sdk_repository_impl,
    environ = [_SDK_ARCHIVE_ENV_VAR],
    attrs = {
        "cipd_tag": attr.string(
            doc = "CIPD tag for the version to load.",
        ),
        "sha256": attr.string_dict(
            doc = "Optional SHA-256 hash of the SDK archive. Valid keys are mac and linux",
        ),
        "_template": attr.label(
            default = "@rules_fuchsia//fuchsia/private:fuchsia_sdk_repository_template.BUILD",
            allow_single_file = True,
        ),
        "_template_directory": attr.label(
            default = "@rules_fuchsia//fuchsia/private/sdk_templates:BUILD.bazel",
            allow_single_file = True,
        ),
    },
)
