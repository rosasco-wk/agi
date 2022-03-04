# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This BUILD file is a template for repositories created by the
# product_repository rule.

load(
    "@rules_fuchsia//fuchsia:defs.bzl",
    "fuchsia_package_group",
)

load(
    "@rules_fuchsia//fuchsia/private:fuchsia_artifact.bzl",
    "fuchsia_artifact",
)

load(
    "@rules_fuchsia//fuchsia/private:fuchsia_core_image.bzl",
    "fuchsia_core_image",
)

load("@rules_fuchsia//fuchsia/private:assembly_bundle.bzl", "assembly_bundle")

sh_binary(
    name = "workspace_checksum_updater",
    srcs = ["workspace_checksum_updater.sh"],
    env = {"SRC": "$(rootpath :checksum.json)"},
    data = [":checksum.json"],
)

{artifact_definitions}
