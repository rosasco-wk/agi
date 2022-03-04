# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load(":providers.bzl", "FuchsiaComponentInfo", "FuchsiaPackageInfo", "FuchsiaPackageResourceInfo")
load(":package_publishing.bzl", "package_repo_path_from_label", "publish_package")

_FuchsiaPackageBuildInfo = provider(
    doc = "A private provider to pass information from a package build to archive.",
    fields = {
        "package_name": "The name of the package",
        "package_manifest": "The manifest file",
    },
)

def _fuchsia_package_impl(ctx):
    sdk = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"]
    package_name = ctx.attr.package_name or ctx.label.name

    # where we will collect all of the temporary files
    pkg_dir = ctx.label.name + "_pkg/"

    # Declare all of the output files
    package_manifest = ctx.actions.declare_file(pkg_dir + "package_manifest")
    meta_package = ctx.actions.declare_file(pkg_dir + "meta/package")
    meta_far = ctx.actions.declare_file(pkg_dir + "meta.far")
    output_package_manifest = ctx.actions.declare_file(ctx.label.name + "_package_manifest.json")

    # All of the resources that will go into the package
    package_resources = [
        # Initially include the meta package
        FuchsiaPackageResourceInfo(
            src = meta_package,
            dest = "meta/package",
        ),
    ]

    # Collect all the resources from the deps
    for dep in ctx.attr.deps:
        if FuchsiaComponentInfo in dep:
            component_info = dep[FuchsiaComponentInfo]
            component_manifest = component_info.manifest

            package_resources.append(
                # add the component manifest
                FuchsiaPackageResourceInfo(
                    src = component_manifest,
                    dest = "meta/%s" % (component_manifest.basename),
                ),
            )
            package_resources.extend(component_info.resources)

        elif FuchsiaPackageResourceInfo in dep:
            # Some resources are added directly to the package
            package_resources.append(dep[FuchsiaPackageResourceInfo])

    # Write our package_manifest file
    ctx.actions.write(
        output = package_manifest,
        content = "\n".join(["%s=%s" % (r.dest, r.src.path) for r in package_resources]),
    )

    # Create the meta/package file
    output_dir = package_manifest.dirname
    ctx.actions.run(
        executable = sdk.pm,
        arguments = [
            "-o",  # output directory
            output_dir,
            "-n",  # name of the package
            package_name,
            "init",
        ],
        outputs = [
            meta_package,
        ],
        mnemonic = "FuchsiaPmInit",
    )

    # The only input to the build step is the package_manifest but we need to
    # include all of the resources as inputs so that if they change the
    # package will get rebuilt.
    build_inputs = [r.src for r in package_resources] + [
        package_manifest,
        meta_package,
    ]

    # Build the package
    ctx.actions.run(
        executable = sdk.pm,
        arguments = [
            "-o",
            output_dir,
            "-m",
            package_manifest.path,
            "-n",
            package_name,
            "build",
            "--output-package-manifest",
            output_package_manifest.path,
        ],
        inputs = build_inputs,
        outputs = [
            output_package_manifest,
            meta_far,
        ],
        mnemonic = "FuchsiaPmBuild",
        progress_message = "Building package for %{label}",
    )

    output_files = [output_package_manifest, meta_far]

    # Attempt to publish if told to do so
    repo_path = package_repo_path_from_label(ctx.attr._package_repo_path)
    if repo_path:
        # TODO: collect all dependent packages
        stamp_file = publish_package(ctx, sdk.pm, repo_path, [output_package_manifest])
        output_files.append(stamp_file)

    return [
        DefaultInfo(files = depset(output_files)),
        _FuchsiaPackageBuildInfo(
            package_name = package_name,
            package_manifest = package_manifest,
        ),
        FuchsiaPackageInfo(
            package_manifest = output_package_manifest,
            files = [output_package_manifest, meta_far] + build_inputs,
        ),
    ]

fuchsia_package = rule(
    doc = """Builds a fuchsia package.

This rule will take a list of dependencies to create a fuchsia package
manifest. The dependencies must provide FuchsiaComponentInfo or
FuchsiaPackageResourceInfo providers to be included in the final package.

Returns a json representation of the package.

To publish a package to a repository during the build phase pass the path to the
repostiory on the command line:
`bazel build //:my_package --@rules_fuchsia//fuchsia:package_repo=out/foo`

```
fuchsia_package_resource(
  name = "text_file",
  src = "my-text.txt",
  dest = "data/my-text.txt",
)

fuchsia_package(
  name = "my_package",
  deps = [":text_file"]
)
```
""",
    implementation = _fuchsia_package_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    attrs = {
        "deps": attr.label_list(
            doc = "The list of dependencies this package depends on",
        ),
        "package_name": attr.string(
            doc = "The name of the package, defaults to the rule name",
        ),
        "_package_repo_path": attr.label(
            doc = "The command line flag used to publish packages.",
            default = "//fuchsia:package_repo",
        ),
    },
)

def _fuchsia_package_archive_impl(ctx):
    package_info = ctx.attr.package[_FuchsiaPackageBuildInfo]
    package_build_outputs = ctx.attr.package[DefaultInfo].files

    archive_name = ctx.attr.archive_name or package_info.package_name

    sdk = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"]

    if archive_name.endswith(".far"):
        far_name = archive_name
    else:
        far_name = archive_name + ".far"

    far_file = ctx.actions.declare_file(far_name)
    output_dir = package_info.package_manifest.dirname

    ctx.actions.run(
        executable = sdk.pm,
        arguments = [
            "-o",
            output_dir,
            "-m",
            package_info.package_manifest.path,
            "-n",
            package_info.package_name,
            "archive",
            "-output",
            # pm automatically adds .far so we have to remove it here to make
            # bazel happy since we need to declare the output with the extension
            far_file.path[:-4],
        ],
        inputs = package_build_outputs,
        outputs = [
            far_file,
        ],
        mnemonic = "FuchsiaPmArchive",
        progress_message = "Archiving package for %{label}",
    )

    return [
        DefaultInfo(files = depset([far_file])),
    ]

fuchsia_package_archive = rule(
    doc = """Creates a fuchsia package archive (far file).

This rule create a far file from a given fuchsia package containing the
package's meta package as well as all of the contained blobs.
""",
    implementation = _fuchsia_package_archive_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    attrs = {
        "package": attr.label(
            doc = "The fuchsia_package to archive",
            mandatory = True,
            providers = [_FuchsiaPackageBuildInfo],
        ),
        "archive_name": attr.string(
            doc = "What to name the archive. The .far file will be appended if not in this name",
        ),
    },
)
