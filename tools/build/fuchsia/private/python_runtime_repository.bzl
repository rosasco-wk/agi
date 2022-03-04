# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines a WORKSPACE rule for loading a version of python3 from CIPD server."""

# Base URL for python3 archives.
_PYTHON3_URL_TEMPLATE = "https://chrome-infra-packages.appspot.com/dl/infra/3pp/tools/cpython3/{os}-amd64/+/version:{version}"

def _python3_url(os, version):
    # Return the URL of the Python3 given an Operating System string and
    # the version.
    # os.name comes in as "mac os x" for osx machines.
    return _PYTHON3_URL_TEMPLATE.format(os = os.split(" ")[0], version = version)

def _instantiate_local(ctx):
    # Extracts the SDK from a local archive file.
    ctx.report_progress("Extracting local SDK archive")
    ctx.extract(archive = ctx.attr.local)

def _python_runtime_repository_impl(ctx):
    ctx.download_and_extract(
        _python3_url(ctx.os.name, ctx.attr.version),
        type = "zip",
    )
    ctx.file(
        "BUILD.bazel",
        """
load("@rules_python//python:defs.bzl", "py_runtime", "py_runtime_pair")
py_runtime(
    name = "python3.9.7",
    # This exclude is needed as there are files in the folder that have space
    # in the filename. Bazel does not support spaces in filename.
    files = glob(["**/*"], exclude = ["**/* *"]),
    interpreter = "bin/python3",
    python_version = "PY3",
)

py_runtime_pair(
    name = "py3.9.7",
    py2_runtime = None,
    py3_runtime = ":python3.9.7",
)

toolchain(
    name = "py3-tc",
    toolchain = ":py3.9.7",
    toolchain_type = "@rules_python//python:toolchain_type",
)
""",
    )

python_runtime_repository = repository_rule(
    doc = """
Fetch specific version of python3 from CIPD server.
""",
    implementation = _python_runtime_repository_impl,
    attrs = {
        "version": attr.string(
            doc = "the version to load.",
        ),
    },
)
