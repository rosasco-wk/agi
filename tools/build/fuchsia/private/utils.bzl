# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Common utilities needed by rules_fuchsia."""

def normalize_os(ctx):
    # On osx os.name => "mac os x".
    return ctx.os.name.split(" ")[0]
