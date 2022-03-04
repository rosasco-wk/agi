# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load(
    ":providers.bzl",
    "AccessTokenInfo",
    "FuchsiaVersionInfo",
)

def _fuchsia_version_impl(ctx):
    return FuchsiaVersionInfo(version = ctx.build_setting_value)

fuchsia_version_string = rule(
    implementation = _fuchsia_version_impl,
    build_setting = config.string(flag = True),
)

def _access_token_impl(ctx):
    return AccessTokenInfo(token = ctx.build_setting_value)

access_token_string = rule(
    implementation = _access_token_impl,
    build_setting = config.string(flag = True),
)
