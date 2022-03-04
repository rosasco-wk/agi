# Copyright 2022 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines a WORKSPACE rule for loading a version of clang."""

load("//fuchsia/private:utils.bzl", "normalize_os")

# Base URL for Fuchsia clang archives.
_CLANG_URL_TEMPLATE = "https://chrome-infra-packages.appspot.com/dl/fuchsia/third_party/clang/{os}-amd64/+/{tag}"

def _clang_url(os, tag):
    # Return the URL of clang given an Operating System string and a CIPD tag.
    return _CLANG_URL_TEMPLATE.format(os = os, tag = tag)

def _instantiate_local(ctx):
    # Extracts the clang from a local archive file.
    ctx.report_progress("Extracting local clang archive")
    ctx.extract(archive = ctx.attr.local_archive)

def _fuchsia_clang_repository_impl(ctx):
    ctx.file("WORKSPACE.bazel", content = "")
    normalized_os = normalize_os(ctx)
    if ctx.attr.cipd_tag:
        sha256 = ""
        if ctx.attr.sha256:
            sha256 = ctx.attr.sha256[normalized_os]
        ctx.download_and_extract(
            _clang_url(normalized_os, ctx.attr.cipd_tag),
            type = "zip",
            sha256 = sha256,
        )
    elif ctx.attr.local_archive:
        _instantiate_local(ctx)
    else:
        fail("One of local_archive or cipd_tag must be set for fuchsia_clang_repository")

    # Set up the BUILD file from the Fuchsia SDK.
    ctx.symlink(
        Label("//fuchsia/private/crosstool:crosstool.BUILD"),
        "BUILD.bazel",
    )

    # Hack to get the path to the sysroot directory, see
    # https://github.com/bazelbuild/bazel/issues/3901
    sysroot_arm64 = str(ctx.path(
        ctx.attr.sdk_root_label.relative(":BUILD.bazel"),
    ).dirname) + "/arch/arm64/sysroot"
    sysroot_x64 = str(ctx.path(
        ctx.attr.sdk_root_label.relative(":BUILD.bazel"),
    ).dirname) + "/arch/x64/sysroot"

    # Set up the toolchain config file from the template.
    ctx.template(
        "cc_toolchain_config.bzl",
        Label("//fuchsia/private/crosstool:cc_toolchain_config_template.bzl"),
        substitutions = {
            "%{SYSROOT_aarch64}": str(sysroot_arm64),
            "%{SYSROOT_x86_64}": str(sysroot_x64),
            "%{CROSSTOOL_ROOT}": str(ctx.path(".")),
        },
    )

fuchsia_clang_repository = repository_rule(
    doc = """
Loads a particular version of clang.

One of cipd_tag or local_archive must be set.

If cipd_tag is set, sha256 can optionally be set to verify the downloaded file
and to allow Bazel to cache the file.

If cipd_tag is not set, local_archive must be set to the path of a core IDK
archive file.
""",
    implementation = _fuchsia_clang_repository_impl,
    attrs = {
        "cipd_tag": attr.string(
            doc = "CIPD tag for the version to load.",
        ),
        "sha256": attr.string_dict(
            doc = "Optional SHA-256 hash of the clang archive. Valid keys are mac and linux",
        ),
        "local_archive": attr.string(
            doc = "local clang archive file.",
        ),
        "sdk_root_label": attr.label(
            doc = "The fuchsia sdk root label. eg: @fuchsia_sdk",
            mandatory = True,
        ),
        "_template": attr.label(
            default = "//fuchsia/private/crosstool:BUILD.crosstool",
            allow_single_file = True,
        ),
        "_template_directory": attr.label(
            default = "//fuchsia/private/sdk_templates:BUILD.bazel",
            allow_single_file = True,
        ),
    },
)
