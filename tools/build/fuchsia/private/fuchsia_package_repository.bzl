# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Build rule for Fuchsia repository

load(":providers.bzl", "FuchsiaArtifactInfo", "FuchsiaPackageGroupInfo", "FuchsiaPackageInfo")

def _fuchsia_package_repository_impl(ctx):
    sdk = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"]
    repo_name = ctx.attr.repo_name or ctx.label.name
    packages = []
    package_deps = []
    for dep in ctx.attr.deps:
        if FuchsiaPackageInfo in dep:
            packages.append(dep[FuchsiaPackageInfo].package_manifest.path)
            package_deps.extend(dep[FuchsiaPackageInfo].files)
        elif FuchsiaPackageGroupInfo in dep:
            for artifact in dep[FuchsiaPackageGroupInfo].artifacts:
                if artifact.type != "package":
                    fail("Non-package artifact included in fuchsia_repository: {}".format(ctx.label.name))

                package_deps.append(artifact.package_manifest)
                packages.append(artifact.package_manifest.path)

    list_of_packages = ctx.actions.declare_file("%s_packages.list" % repo_name)

    ctx.actions.write(
        output = list_of_packages,
        content = "\n".join(packages),
    )

    # Publish the packages
    repo_dir = ctx.actions.declare_directory("%s.repo" % repo_name)
    ctx.actions.run(
        executable = sdk.pm,
        arguments = [
            "publish",
            "-C",
            "-lp",
            "-f",
            list_of_packages.path,
            "-repo",
            repo_dir.path,
        ],
        inputs = depset(package_deps + [list_of_packages]),
        outputs = [
            repo_dir,
        ],
        mnemonic = "FuchsiaPmPublish",
        progress_message = "Publishing package repository %{label}",
    )

    print("Published! To register this repository, use 'ffx target repository register -r %s %s'" % (repo_name, repo_dir.path))

    return [DefaultInfo(files = depset([repo_dir]))]

fuchsia_package_repository = rule(
    doc = """
A Fuchsia TUF package repository as created by the 'pm' tool and used by 'ffx repository'.
""",
    implementation = _fuchsia_package_repository_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    attrs = {
        "deps": attr.label_list(
            doc = "Fuchsia package and package groups to include in this repository.",
            providers = [
                [FuchsiaPackageInfo],
                [FuchsiaPackageGroupInfo],
            ],
        ),
        "repo_name": attr.string(
            doc = "The repository name, defaults to the rule name",
            mandatory = False,
        ),
    },
)
