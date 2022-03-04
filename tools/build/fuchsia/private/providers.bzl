# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""All Fuchsia Providers."""

FuchsiaArtifactInfo = provider(
    doc = "A pre-built artifact used for product assembly.",
    fields = {
        "attributes": "String key-value dictionary of attributes.",
        "blobs": "A list of blobs this artifact depends on.",
        "blob_manifest": "A file mapping merkleroots to paths.",
        "file": "The artifact file.",
        "name": "The group-unique name of the artifact.",
        "package_manifest": "JSON package manifest file, if this artifact is a package.",
        "type": "A string representing the type of artifact.",
    },
)

FuchsiaComponentInfo = provider(
    "Contains information about a fuchsia component",
    fields = {
        "name": "name of the component",
        "manifest": "A file representing the compiled component manifest file",
        "resources": "any additional resources the component needs",
    },
)

FuchsiaFidlLibraryInfo = provider(
    "Contains information about a FIDL library",
    fields = {
        "info": "List of structs(name, files) representing the library's dependencies",
        "name": "Name of the FIDL library",
        "ir": "Path to the JSON file with the library's intermediate representation",
    },
)

FuchsiaCoreImageInfo = provider(
    "Private provider containing platform artifacts",
    fields = {
        "esp_blk": "EFI system partition image.",
        "kernel_zbi": "Zircon image.",
        "vbmetar": "vbmeta for zirconr boot image.",
        "zirconr": "zedboot boot image.",
    },
)

FuchsiaPackageResourceInfo = provider(
    "Contains the source and destination of a package resource",
    fields = {
        "dest": "Where to install this resource in the package",
        "src": "The path to the resource on disk",
    },
)

FuchsiaPackageResourceGroupInfo = provider(
    "Contains a collection of resources to include in a package",
    fields = {
        "resources": "A list of FuchsiaPackageResourceInfo providers",
    },
)

FuchsiaPackageGroupInfo = provider(
    doc = "The raw files that make up a set of fuchsia packages.",
    fields = {
        "artifacts": "a list of artifacts this group depends on",
    },
)

FuchsiaPackageInfo = provider(
    doc = "Contains information about a fuchsia package.",
    fields = {
        "package_manifest": "JSON package manifest file representing the Fuchsia package.",
        "files": "all files that define this package, including the manifest and meta.far",
    },
)

FuchsiaProductImageInfo = provider(
    doc = "Info needed to pave a Fuchsia image",
    fields = {
        "esp_blk": "EFI system partition image.",
        "blob_blk": "BlobFS partition image.",
        "data_blk": "MinFS partition image.",
        "images_json": "images.json file",
        "kernel_zbi": "Zircon image.",
        "vbmetaa": "vbmeta for zircona boot image.",
        "vbmetar": "vbmeta for zirconr boot image.",
        "zircona": "main boot image.",
        "zirconr": "zedboot boot image.",
    },
)

FuchsiaAssemblyConfigInfo = provider(
    doc = "Private provider that includes a single JSON configuration file.",
    fields = {
        "config": "JSON configuration file",
        "package_manifests": "List of package_manifest.json files included in the base, cache and system",
        "blobs": "List of blobs used by this product",
    },
)

FuchsiaProductBuildInfo = provider(
    doc = "A build-info used to create build-info.json in release structure.",
    fields = {
        "board": "The JSON board configuration file used in image assembly.",
        "manifest": "The manifest.json file which contains the version info.",
        "update_manifest": "update_package_manifest.json file needed by OTA.",
        "base_manifest": "base_package_manifest.json file needed by OTA.",
    },
)

FuchsiaProductAssemblyBundleInfo = provider(
    doc = """
A bundle of files used by product assembly.
This should only be provided by the single exported target of a
fuchsia_product_assembly_bundle repository.
""",
    fields = {
        "root": "A blank file at the root of the bundle directory",
        "files": "All files contained in the bundle",
    },
)

FuchsiaVersionInfo = provider(
    doc = "version information passed in that overwrite sdk version",
    fields = {
        "version": "The version string.",
    },
)

AccessTokenInfo = provider(
    doc = "Access token used to upload to MOS repository",
    fields = {
        "token": "The token string.",
    },
)

FuchsiaPackageRepoPathInfo = provider(
    doc = "A provider which provides the path to a fuchsia package repo",
    fields = {
        "path": "The path to the repository. ",
    },
)
