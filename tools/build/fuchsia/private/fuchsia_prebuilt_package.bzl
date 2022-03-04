# Copyright 2022 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load(":providers.bzl", "FuchsiaPackageInfo")
load(":package_publishing.bzl", "package_repo_path_from_label", "publish_package")

def _relative_file_name(ctx, filename):
    return ctx.label.name + "_expanded/" + filename

def _fuchsia_prebuilt_package_impl(ctx):
    sdk = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"]
    far_archive = ctx.files.archive[0]

    package_manifest_json = ctx.actions.declare_file(_relative_file_name(ctx, "package_manifest.json"))

    # extract the package
    ctx.actions.run(
        executable = sdk.pm,
        arguments = [
            "-o",
            package_manifest_json.dirname,
            "expand",
            far_archive.path,
        ],
        inputs = [far_archive],
        outputs = [
            package_manifest_json,
        ],
        mnemonic = "FuchsiaPmExpand",
        progress_message = "expanding package for %{label}",
    )

    output_files = []

    # Attempt to publish if told to do so
    repo_path = package_repo_path_from_label(ctx.attr._package_repo_path)
    if repo_path != "":
        stamp_file = publish_package(ctx, sdk.pm, repo_path, [package_manifest_json])
        output_files.append(stamp_file)

    return [
        DefaultInfo(files = depset(output_files)),
        FuchsiaPackageInfo(
            package_manifest = package_manifest_json,
        ),
    ]

fuchsia_prebuilt_package = rule(
    doc = """Provides access to a fuchsia package from a prebuilt package (.far).
""",
    implementation = _fuchsia_prebuilt_package_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    attrs = {
        "archive": attr.label(
            doc = "The fuchsia archive",
            allow_single_file = True,
            mandatory = True,
        ),
        "_package_repo_path": attr.label(
            doc = "The command line flag used to publish packages.",
            default = "//fuchsia:package_repo",
        ),
    },
)
