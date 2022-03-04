# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rule for generate release structure. The structure looks like:
    ├── blobs
    │   └── <blobs>
    └── namespace
        ├── images
        │       └── <images>
        ├── build_api
        │       ├── tool_paths.json (dummy)
        │       └── build_info.json
        ├── packages
        │       ├── all_blobs.json
        │       └── repository
        │              ├── targets
        │              │       ├── update/
        │              │       ├── system_image/
        │              │       └── <other target files>
        │              └── targets.json
        └── jiri_snapshot.xml (dummy)

"""

load(
    ":providers.bzl",
    "FuchsiaAssemblyConfigInfo",
    "FuchsiaProductBuildInfo",
    "FuchsiaProductImageInfo",
    "FuchsiaVersionInfo",
)

def _fuchsia_product_release_impl(ctx):
    build_info = ctx.attr.product_image[FuchsiaProductBuildInfo]
    assembly_config = ctx.attr.product_image[FuchsiaAssemblyConfigInfo]

    # Generate the all_blobs.json file and populate blobs/ dir
    package_manifests = assembly_config.package_manifests + [build_info.update_manifest, build_info.base_manifest]
    package_manifest_paths = [manifest.path for manifest in package_manifests]
    blobs_dir = ctx.actions.declare_directory(ctx.label.name + "/blobs/")
    all_blobs_files = ctx.actions.declare_file(ctx.label.name + "/namespace/packages/all_blobs.json")

    args = ctx.actions.args()
    args.add_joined("--package-manifests", package_manifest_paths, join_with = ",")
    args.add("--output-file", all_blobs_files.path)
    args.add("--build-path", ctx.file.lock_file.dirname)
    args.add("--output-blobs-dir", blobs_dir.path)

    ctx.actions.run(
        outputs = [all_blobs_files, blobs_dir],
        inputs = package_manifests + [ctx.file.lock_file],
        executable = ctx.executable._all_blobs_creator,
        arguments = [args],
    )
    out_files = [all_blobs_files]

    # Generate the build_info.json file
    build_info_file = ctx.actions.declare_file(ctx.label.name + "/namespace/build_api/build_info.json")
    args = ctx.actions.args()
    args.add("--board-file", build_info.board.path)
    args.add("--manifest-file", build_info.manifest.path)
    args.add("--product-name", "workstation-oot")
    args.add("--output-file", build_info_file.path)
    args.add("--overwrite-version", ctx.attr._version[FuchsiaVersionInfo].version)

    ctx.actions.run(
        outputs = [build_info_file],
        inputs = [build_info.board, build_info.manifest],
        executable = ctx.executable._build_info_creator,
        arguments = [args],
    )
    out_files += [build_info_file]

    # Generate the images/ directory
    output_images_json_file = ctx.actions.declare_file(ctx.label.name + "/namespace/images/images.json")
    original_images_json = ctx.attr.product_image[FuchsiaProductImageInfo].images_json
    args = ctx.actions.args()
    args.add("--build-path", ctx.file.lock_file.dirname)
    args.add("--images-json-path", original_images_json.path)
    args.add("--output", output_images_json_file.path)

    ctx.actions.run(
        outputs = [output_images_json_file],
        inputs = [original_images_json],
        executable = ctx.executable._images_creator,
        arguments = [args],
    )
    out_files += [output_images_json_file]

    # Generate the dummy tool_paths.json
    tool_path_json_file = ctx.actions.declare_file(ctx.label.name + "/namespace/build_api/tool_paths.json")
    ctx.actions.write(tool_path_json_file, "[]")
    out_files += [tool_path_json_file]

    # Generate the dummy jiri_snapshot.xml
    jiri_snapshot_xml_file = ctx.actions.declare_file(ctx.label.name + "/namespace/jiri_snapshot.xml")
    ctx.actions.write(jiri_snapshot_xml_file, "")
    out_files += [jiri_snapshot_xml_file]

    # Generate the targets.json file and the targets/ directory
    targets_json_file = ctx.actions.declare_file(ctx.label.name + "/namespace/packages/repository/targets.json")

    args = ctx.actions.args()
    args.add_joined("--package-manifests", package_manifest_paths, join_with = ",")
    args.add("--blobs-dir", blobs_dir.path)
    args.add("--build-path", ctx.file.lock_file.dirname)
    args.add("--output-file", targets_json_file.path)

    ctx.actions.run(
        outputs = [targets_json_file],
        inputs = [ctx.file.lock_file] + package_manifests,
        executable = ctx.executable._targets_json_creator,
        arguments = [args],
    )
    out_files += [targets_json_file]

    return [
        DefaultInfo(files = depset(direct = out_files)),
    ]

fuchsia_product_release = rule(
    doc = "Declares a release archive.",
    implementation = _fuchsia_product_release_impl,
    attrs = {
        "product_image": attr.label(
            mandatory = True,
            doc = "Core image to provide board files.",
            providers = [FuchsiaProductImageInfo, FuchsiaAssemblyConfigInfo, FuchsiaProductBuildInfo],
        ),
        # TODO: We will remove the lock file dependency
        "lock_file": attr.label(
            doc = "The lock file which contains the list of packages needed",
            allow_single_file = [".json"],
            mandatory = True,
        ),
        "_version": attr.label(
            doc = "The version number that overwrites the sdk version.",
            default = ":build_version",
        ),
        "_images_creator": attr.label(
            executable = True,
            cfg = "exec",
            default = "//tools:images_creator",
        ),
        "_all_blobs_creator": attr.label(
            executable = True,
            cfg = "exec",
            default = "//tools:all_blobs_creator",
        ),
        "_build_info_creator": attr.label(
            executable = True,
            cfg = "exec",
            default = "//tools:build_info_creator",
        ),
        "_targets_json_creator": attr.label(
            executable = True,
            cfg = "exec",
            default = "//tools:targets_json_creator",
        ),
    },
)
