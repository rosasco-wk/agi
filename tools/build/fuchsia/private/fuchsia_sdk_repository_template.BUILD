# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This BUILD file is mapped into a downloaded Fuchsia SDK.
#
# This is referenced by //fuchsia/private/fuchsia_sdk_repository.bzl, see
# the `fuchsia_sdk_repository` rule for more information.
load("@rules_fuchsia//fuchsia:defs.bzl", "fuchsia_toolchain_info")

# Export all files as individual targets.
exports_files(glob(["**/*"]))

# A single target that includes all files in the SDK.
filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//visibility:public"],
)

constraint_value(
    name = "fuchsia_toolchain_version_sdk",
    constraint_setting = "@rules_fuchsia//fuchsia/constraints:version",
)

# Toolchain has additional tools if the DDK is included.
# This is a temporary implementation while the DDK is experimental and not
# published with the SDK. Once the DDK tools are present in the SDK
# these settings and the template field 'has_ddk' can be removed.
constraint_setting(
    name = "sdk_setup",
    default_constraint_value = ":{{has_ddk}}",
)

constraint_value(
    name = "has_ddk",
    constraint_setting = "sdk_setup",
)

constraint_value(
    name = "no_ddk",
    constraint_setting = "sdk_setup",
)

platform(
    name = "fuchsia_platform_sdk",
    constraint_values = [":fuchsia_toolchain_version_sdk"],
    visibility = ["//visibility:public"],
)

fuchsia_toolchain_info(
    name = "fuchsia_toolchain_info",
    blobfs = "//tools:x64/blobfs_do_not_depend",
    bootserver = "//tools:x64/bootserver",
    cmc = "//tools:x64/cmc",
    far = "//tools:x64/far",
    ffx = "//tools:x64/ffx",
    fidlc = "//tools:x64/fidlc",
    fidlgen = "//tools:x64/fidlgen",
    fvm = "//tools:x64/fvm",
    merkleroot = "//tools:x64/merkleroot",
    pm = "//tools:x64/pm",
    zbi = "//tools:x64/zbi",
    bindc = select({
        ":has_ddk": "//tools:x64/bindc",
        ":no_ddk": None,
    }),
    fidlgen_banjo = select({
        ":has_ddk": "//tools:x64/fidlgen_banjo",
        ":no_ddk": None,
    }),
    fidlgen_llcpp = select({
        ":has_ddk": "//tools:x64/fidlgen_llcpp_experimental_driver_only_toolchain",
        ":no_ddk": None,
    }),
)

toolchain(
    name = "fuchsia_toolchain_sdk",
    toolchain = ":fuchsia_toolchain_info",
    toolchain_type = "@rules_fuchsia//fuchsia:toolchain",
)
