# Copyright 2022 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "feature", "flag_group", "flag_set", "tool_path")

def _cc_toolchain_config_impl(ctx):
    target_system_name = ctx.attr.cpu + "-fuchsia"
    tool_paths = [
        tool_path(
            name = "ar",
            path = "bin/llvm-ar",
        ),
        tool_path(
            name = "cpp",
            path = "bin/clang++",
        ),
        tool_path(
            name = "gcc",
            path = "bin/clang",
        ),
        tool_path(
            name = "lld",
            path = "bin/lld",
        ),
        tool_path(
            name = "objdump",
            path = "bin/llvm-objdump",
        ),
        tool_path(
            name = "strip",
            path = "bin/llvm-strip",
        ),
        tool_path(
            name = "nm",
            path = "bin/llvm-nm",
        ),
        tool_path(
            name = "objcopy",
            path = "bin/llvm-objcopy",
        ),
        tool_path(
            name = "dwp",
            path = "/not_available/dwp",
        ),
        tool_path(
            name = "compat-ld",
            path = "/not_available/compat-ld",
        ),
        tool_path(
            name = "gcov",
            path = "/not_available/gcov",
        ),
        tool_path(
            name = "gcov-tool",
            path = "/not_available/gcov-tool",
        ),
        tool_path(
            name = "ld",
            path = "bin/ld.lld",
        ),
    ]
    features = [
        feature(
            name = "default_compile_flags",
            flag_sets = [
                flag_set(
                    actions = [
                        "assemble",
                        "preprocess-assemble",
                        "linkstamp-compile",
                        "c-compile",
                        "c++-compile",
                        "c++-header-parsing",
                        "c++-module-compile",
                        "c++-module-codegen",
                        "lto-backend",
                        "clif-match",
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "--target=" + target_system_name,
                                "-Wall",
                                "-Werror",
                                "-Wextra-semi",
                                "-Wnewline-eof",
                                # TODO(mangini): llcpp is causing shadow errors, see why and reenable: "-Wshadow",
                            ],
                        ),
                    ],
                ),
                flag_set(
                    actions = [
                        "linkstamp-compile",
                        "c++-compile",
                        "c++-header-parsing",
                        "c++-module-compile",
                        "c++-module-codegen",
                        "lto-backend",
                        "clif-match",
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-std=c++17",
                                "-xc++",
                                # Needed to compile shared libraries.
                                "-fPIC",
                            ],
                        ),
                    ],
                ),
            ],
            enabled = True,
        ),
        feature(
            name = "default_link_flags",
            flag_sets = [
                flag_set(
                    actions = [
                        "c++-link-executable",
                        "c++-link-dynamic-library",
                        "c++-link-nodeps-dynamic-library",
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "--target=" + target_system_name,
                                "--driver-mode=g++",
                                "-lzircon",
                            ],
                        ),
                    ],
                ),
            ],
            enabled = True,
        ),
        feature(
            name = "supports_pic",
            enabled = True,
        ),
    ]
    sysroots = {
        "aarch64": "%{SYSROOT_aarch64}",
        "x86_64": "%{SYSROOT_x86_64}",
    }
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "crosstool-1.x.x-llvm-fuchsia-" + ctx.attr.cpu,
        host_system_name = "x86_64-unknown-linux-gnu",
        target_system_name = target_system_name,
        target_cpu = ctx.attr.cpu,
        target_libc = "fuchsia",
        compiler = "llvm",
        abi_version = "local",
        abi_libc_version = "local",
        tool_paths = tool_paths,
        # Implicit dependencies for Fuchsia system functionality
        cxx_builtin_include_directories = [
            sysroots[ctx.attr.cpu] + "/include",  # Platform parts of libc.
            "%{CROSSTOOL_ROOT}/include/" + ctx.attr.cpu + "-unknown-fuchsia/c++/v1",  # Platform libc++.
            "%{CROSSTOOL_ROOT}/include/c++/v1",  # Platform libc++.
            "%{CROSSTOOL_ROOT}/lib/clang/14.0.0/include",  # Platform libc++.
        ],
        builtin_sysroot = sysroots[ctx.attr.cpu],
        features = features,
        cc_target_os = "fuchsia",
    )

cc_toolchain_config = rule(
    implementation = _cc_toolchain_config_impl,
    attrs = {
        "cpu": attr.string(mandatory = True, values = ["aarch64", "x86_64"]),
    },
    provides = [CcToolchainConfigInfo],
)
