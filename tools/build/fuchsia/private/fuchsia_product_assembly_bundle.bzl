# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Repository rule for including a Product Assembly Bundle."""

_doc = """
A Product Assembly Bundle from a local Fuchsia build.

archive must be set to the path of a bundle archive file.

Currently, the archive can be built in-tree by running the command:

`fx build build/assembly:legacy.tgz`

This will result in the file
"$(fx get-build-dir)/obj/build/assembly/legacy.tgz"

archive must be set to this path.

Currently, the tar file does not contain a required file, assembly_config.json.
As a workaround, a second parameter 'config' is also required. The file can
be found at "$(fx get-build-dir)/obj/build/assembly/legacy/assembly_config.json"
after the same build. This is temporary.

TODO(lijiaming): remove assembly_config.json parameter and logic.

"""

_build_content = """

load("@rules_fuchsia//fuchsia/private:assembly_bundle.bzl", "assembly_bundle")

filegroup(
    name = "all_content",
    srcs = glob(["legacy/**"], exclude = [
      "WORKSPACE",
      "BUILD.bazel",
    ]),
)

assembly_bundle(
    name = "$repository_name",
    root = ":root",
    files = ":all_content",
    visibility = ["//visibility:public"],
)
"""

def _fuchsia_product_assembly_bundle_impl(ctx):
    build_content = _build_content.replace("$repository_name", ctx.name)
    ctx.file("BUILD.bazel", content = build_content)
    ctx.extract(ctx.attr.archive, output = "legacy")
    ctx.file("root")

    # TODO(lijiaming): Remove these two lines once assembly-config is included
    # in the bundle archive.
    config_content = ctx.read(ctx.attr.config)
    ctx.file("legacy/assembly_config.json", content = config_content)

fuchsia_product_assembly_bundle = repository_rule(
    implementation = _fuchsia_product_assembly_bundle_impl,
    doc = _doc,
    attrs = {
        # TODO(lijiaming): Remove this attribute once assembly-config is
        # included in the bundle archive.
        "config": attr.string(
            doc = "Path to the bundle assembly_config file.",
            mandatory = True,
        ),
        "archive": attr.string(
            doc = "Path to the bundle archive file.",
            mandatory = True,
        ),
    },
)
