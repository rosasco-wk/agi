# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule for creating a JSON image configuration for ffx assembly."""

load(
    ":providers.bzl",
    "FuchsiaArtifactInfo",
    "FuchsiaAssemblyConfigInfo",
    "FuchsiaCoreImageInfo",
    "FuchsiaPackageGroupInfo",
    "FuchsiaVersionInfo",
)

def _update_build_info_package_manifest(ctx, artifact, version_file):
    far_tool = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"].far
    ffx_tool = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"].ffx
    package_file = ctx.actions.declare_file("package")
    ctx.actions.write(package_file, "{\"name\":\"build-info\",\"version\":\"0\"}")
    build_manifest_file = ctx.actions.declare_file("build_manifest")
    package_manifest_file = ctx.actions.declare_file("build-info_artifact_package_manifest.json")
    blob_paths = [blob.path for blob in artifact.blobs]

    args = ctx.actions.args()
    args.add("--far-tool", far_tool.path)
    args.add("--ffx-tool", ffx_tool.path)
    args.add("--version-file", version_file.path)
    args.add("--package-file", package_file.path)
    args.add("--build-manifest-file", build_manifest_file.path)
    args.add("--meta-far-file", artifact.file.path)
    args.add("--package-manifest", package_manifest_file.path)
    args.add_joined("--blobs", blob_paths, join_with = ",")

    ctx.actions.run(
        outputs = [package_manifest_file, build_manifest_file],
        inputs = [version_file, package_file, artifact.file] + artifact.blobs,
        executable = ctx.executable._version_updater,
        arguments = [args],
    )
    return package_manifest_file

# Loads package manifest JSON files from each artifact in the given
# package_group attribute, which must contain a FuchsiaPackageGroupInfo
# provider.
def _get_package_manifests(ctx, package_group, version_file):
    manifests = []
    if not package_group:
        return manifests
    for artifact in package_group[FuchsiaPackageGroupInfo].artifacts:
        if artifact.package_manifest:
            if artifact.name == "build-info/0" and ctx.attr._version[FuchsiaVersionInfo].version != "None":
                manifests.append(_update_build_info_package_manifest(ctx, artifact, version_file))
            else:
                manifests.append(artifact.package_manifest)
    return manifests

# Retrieves the blob dependencies of the given package_group attribute
# as a list of File objects. package_group must contain a
# FuchsiaPackageGroupInfo object.
def _get_blobs(package_group):
    blobs = []
    if not package_group:
        return blobs
    for artifact in package_group[FuchsiaPackageGroupInfo].artifacts:
        blobs.extend(artifact.blobs)
    return blobs

def _fuchsia_product_configuration_impl(ctx):
    # Creates the config file by creating package manifests for all included
    # packages, and placing them into a Starlark dictionary. The dictionary
    # is then converted to JSON and written to a file.

    initial_config_file = ctx.actions.declare_file("_initial_" + ctx.label.name + ".json")
    version_file = ctx.actions.declare_file("version")
    ctx.actions.write(version_file, ctx.attr._version[FuchsiaVersionInfo].version)

    base_package_manifests = _get_package_manifests(ctx, ctx.attr.base_package_group, version_file)
    cache_package_manifests = _get_package_manifests(ctx, ctx.attr.cache_package_group, version_file)
    system_package_manifests = _get_package_manifests(ctx, ctx.attr.system_package_group, version_file)
    kernel_zbi = ctx.attr.core_image[FuchsiaCoreImageInfo].kernel_zbi
    config = {
        "base": [manifest.path for manifest in base_package_manifests],
        "boot_args": ctx.attr.boot_args,
        "cache": [manifest.path for manifest in cache_package_manifests],
        "system": [manifest.path for manifest in system_package_manifests],
        "kernel": {
            "args": ctx.attr.kernel_args,
            "clock_backstop": ctx.attr.clock_backstop,
            "path": kernel_zbi.path,
        },
    }
    ctx.actions.write(initial_config_file, json.encode_indent(config))

    config_file = ctx.actions.declare_file(ctx.label.name + ".json")
    bootfs_artifact = ctx.attr.bootfs_files[FuchsiaArtifactInfo]
    ctx.actions.run(
        outputs = [config_file],
        inputs = [
            initial_config_file,
            bootfs_artifact.package_manifest,
            bootfs_artifact.blob_manifest,
        ],
        executable = ctx.executable._product_config_bootfs_appender,
        arguments = [
            "--input",
            initial_config_file.path,
            "--output",
            config_file.path,
            "--blob_manifest",
            bootfs_artifact.blob_manifest.path,
            "--package_manifest",
            bootfs_artifact.package_manifest.path,
        ],
    )

    # Collects the config file, all package manifests referenced by the config,
    # and all blobs referenced by the package manifests into one depset, so
    # they are provided to targets that depend on this configuration.

    all_package_manfiests = (base_package_manifests +
                             cache_package_manifests +
                             system_package_manifests)
    direct_deps = (
        [config_file, kernel_zbi] + all_package_manfiests
    )
    all_blobs = []
    all_blobs.extend(_get_blobs(ctx.attr.base_package_group))
    all_blobs.extend(_get_blobs(ctx.attr.cache_package_group))
    all_blobs.extend(_get_blobs(ctx.attr.system_package_group))
    all_blobs.append(version_file)

    direct_deps.extend(all_blobs)
    direct_deps.extend(bootfs_artifact.blobs)

    return [
        DefaultInfo(files = depset(direct = direct_deps)),
        FuchsiaAssemblyConfigInfo(config = config_file, package_manifests = all_package_manfiests, blobs = all_blobs),
    ]

fuchsia_product_configuration = rule(
    doc = "A JSON configuration for a Fuchsia image, for use by ffx assembly.",
    implementation = _fuchsia_product_configuration_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    provides = [FuchsiaAssemblyConfigInfo],
    attrs = {
        "base_package_group": attr.label(
            doc = "Package group to be included in 'base' for the product image.",
            providers = [FuchsiaPackageGroupInfo],
        ),
        "boot_args": attr.string_list(
            doc = "Kernel boot arguments",
        ),
        "bootfs_files": attr.label(
            doc = "Fuchsia artifact of type 'package' with files for inclusion in BootFS.",
            providers = [FuchsiaArtifactInfo],
            mandatory = True,
        ),
        "cache_package_group": attr.label(
            doc = "Package group to be included in 'cache' for the product image.",
            providers = [FuchsiaPackageGroupInfo],
        ),
        "clock_backstop": attr.int(
            doc = "Earliest UTC timestamp that the system can be set to.",
            mandatory = True,
        ),
        "core_image": attr.label(
            doc = "Fuchsia core_image target.",
            providers = [FuchsiaCoreImageInfo],
        ),
        "kernel_args": attr.string_list(
            doc = "Arguments provided to kernel.",
        ),
        "system_package_group": attr.label(
            doc = "Packages that will be merged into the system package (the base package).",
            providers = [FuchsiaPackageGroupInfo],
        ),
        "_product_config_bootfs_appender": attr.label(
            executable = True,
            cfg = "exec",
            default = "//tools:product_config_bootfs_appender",
        ),
        "_version_updater": attr.label(
            executable = True,
            cfg = "exec",
            default = "//tools:version_updater",
        ),
        "_version": attr.label(
            doc = "The version number that overwrites the sdk version.",
            default = ":build_version",
        ),
    },
)
