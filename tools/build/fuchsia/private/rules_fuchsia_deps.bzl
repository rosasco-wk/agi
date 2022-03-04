# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Loads external repositores needed by rules_fuchsia."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load(
    "//fuchsia/private:python_runtime_repository.bzl",
    "python_runtime_repository",
)

def rules_fuchsia_deps():
    maybe(
        name = "rules_python",
        repo_rule = http_archive,
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.5.0/rules_python-0.5.0.tar.gz",
        sha256 = "cd6730ed53a002c56ce4e2f396ba3b3be262fd7cb68339f0377a45e8227fe332",
    )

    maybe(
        name = "python_runtime",
        repo_rule = python_runtime_repository,
        version = "2@3.9.7.chromium.19",
    )
