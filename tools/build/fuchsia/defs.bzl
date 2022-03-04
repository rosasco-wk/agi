# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Public definitions for Fuchsia rules.

Documentation for all rules exported by this file is located at docs/defs.md"""

load(
    "@//tools/build/fuchsia/private:fuchsia_artifact.bzl",
    _fuchsia_artifact = "fuchsia_artifact",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_artifact_release.bzl",
    _fuchsia_artifact_release = "fuchsia_artifact_release",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_board_configuration.bzl",
    _fuchsia_board_configuration = "fuchsia_board_configuration",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_bind_library.bzl",
    _fuchsia_bind_library = "fuchsia_bind_library",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_component.bzl",
    _fuchsia_component = "fuchsia_component",
    _fuchsia_component_manifest = "fuchsia_component_manifest",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_unittest_component.bzl",
    _fuchsia_unittest_component = "fuchsia_unittest_component",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_fidl_library.bzl",
    _fuchsia_fidl_library = "fuchsia_fidl_library",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_fidl_cc_library.bzl",
    _fuchsia_fidl_hlcpp_library = "fuchsia_fidl_hlcpp_library",
    _fuchsia_fidl_llcpp_library = "fuchsia_fidl_llcpp_library",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_banjo_cc_library.bzl",
    _fuchsia_banjo_cc_library = "fuchsia_banjo_cc_library",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_driver_bind_rules.bzl",
    _fuchsia_driver_bytecode_bind_rules = "fuchsia_driver_bytecode_bind_rules",
    _fuchsia_driver_header_bind_rules = "fuchsia_driver_header_bind_rules",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_package.bzl",
    _fuchsia_package = "fuchsia_package",
    _fuchsia_package_archive = "fuchsia_package_archive",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_image_paver.bzl",
    _fuchsia_image_paver = "fuchsia_image_paver",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_prebuilt_package.bzl",
    _fuchsia_prebuilt_package = "fuchsia_prebuilt_package",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_product_configuration.bzl",
    _fuchsia_product_configuration = "fuchsia_product_configuration",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_product_release.bzl",
    _fuchsia_product_release = "fuchsia_product_release",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_package_group.bzl",
    _fuchsia_package_group = "fuchsia_package_group",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_product_image.bzl",
    _fuchsia_product_image = "fuchsia_product_image",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_toolchain_info.bzl",
    _fuchsia_toolchain_info = "fuchsia_toolchain_info",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_package_resource.bzl",
    _fuchsia_package_resource = "fuchsia_package_resource",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_package_repository.bzl",
    _fuchsia_package_repository = "fuchsia_package_repository",
)
load(
    "@//tools/build/fuchsia/private:artifact_lock_updater.bzl",
    _artifact_lock_updater = "artifact_lock_updater",
)
load(
    "@//tools/build/fuchsia/private:build_setting.bzl",
    _access_token_string = "access_token_string",
    _fuchsia_version_string = "fuchsia_version_string",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_select.bzl",
    _fuchsia_select = "fuchsia_select",
)
load(
    "@//tools/build/fuchsia/private:fuchsia_product.bzl",
    _fuchsia_product = "fuchsia_product",
)
load(
    "@//tools/build/fuchsia/private:providers.bzl",
    _FuchsiaArtifactInfo = "FuchsiaArtifactInfo",
    _FuchsiaPackageGroupInfo = "FuchsiaPackageGroupInfo",
    _FuchsiaProductAssemblyBundleInfo = "FuchsiaProductAssemblyBundleInfo",
    _FuchsiaProductImageInfo = "FuchsiaProductImageInfo",
)
load(
    "@//tools/build/fuchsia/private:compilation_database.bzl",
    _clangd_compilation_database = "clangd_compilation_database",
)

# Rules

artifact_lock_updater = _artifact_lock_updater
fuchsia_artifact = _fuchsia_artifact
fuchsia_artifact_release = _fuchsia_artifact_release
fuchsia_board_configuration = _fuchsia_board_configuration
fuchsia_image_paver = _fuchsia_image_paver
fuchsia_bind_library = _fuchsia_bind_library
fuchsia_component = _fuchsia_component
fuchsia_unittest_component = _fuchsia_unittest_component
fuchsia_component_manifest = _fuchsia_component_manifest
fuchsia_driver_bytecode_bind_rules = _fuchsia_driver_bytecode_bind_rules
fuchsia_driver_header_bind_rules = _fuchsia_driver_header_bind_rules
fuchsia_fidl_library = _fuchsia_fidl_library
fuchsia_fidl_hlcpp_library = _fuchsia_fidl_hlcpp_library
fuchsia_fidl_llcpp_library = _fuchsia_fidl_llcpp_library
fuchsia_banjo_cc_library = _fuchsia_banjo_cc_library
fuchsia_package = _fuchsia_package
fuchsia_package_archive = _fuchsia_package_archive
fuchsia_prebuilt_package = _fuchsia_prebuilt_package
fuchsia_product = _fuchsia_product
fuchsia_product_configuration = _fuchsia_product_configuration
fuchsia_package_group = _fuchsia_package_group
fuchsia_product_release = _fuchsia_product_release
fuchsia_product_image = _fuchsia_product_image
fuchsia_toolchain_info = _fuchsia_toolchain_info
fuchsia_package_resource = _fuchsia_package_resource
fuchsia_package_repository = _fuchsia_package_repository
fuchsia_select = _fuchsia_select
fuchsia_version_string = _fuchsia_version_string
access_token_string = _access_token_string
clangd_compilation_database = _clangd_compilation_database

# Providers

FuchsiaArtifactInfo = _FuchsiaArtifactInfo
FuchsiaPackageGroupInfo = _FuchsiaPackageGroupInfo
FuchsiaProductImageInfo = _FuchsiaProductImageInfo
FuchsiaProductAssemblyBundleInfo = _FuchsiaProductAssemblyBundleInfo
