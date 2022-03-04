# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Build rule for pre-built Fuchsia Packages

load(":providers.bzl", "FuchsiaArtifactInfo", "FuchsiaPackageGroupInfo")

def _fuchsia_package_group_impl(ctx):
    artifacts = []
    for artifact in ctx.attr.deps:
        if FuchsiaArtifactInfo in artifact:
            artifacts.append(artifact[FuchsiaArtifactInfo])
        elif FuchsiaPackageGroupInfo in artifact:
            artifacts.extend(artifact[FuchsiaPackageGroupInfo].artifacts)

    for a in artifacts:
        if a.type != "package":
            fail("Non-package artifact included in fuchsia_package_group: {}".format(ctx.label.name))

    return [FuchsiaPackageGroupInfo(artifacts = artifacts)]

fuchsia_package_group = rule(
    doc = """
A group of Fuchsia packages, composed of all the artifacts and groups specified in deps.
""",
    implementation = _fuchsia_package_group_impl,
    attrs = {
        "deps": attr.label_list(
            doc = "Fuchsia artifacts and package groups to include in this group.",
            providers = [
                [FuchsiaArtifactInfo],
                [FuchsiaPackageGroupInfo],
            ],
        ),
    },
)
