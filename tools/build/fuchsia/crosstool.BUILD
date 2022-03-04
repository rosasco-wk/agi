load(":cc_toolchain_config.bzl", "cc_toolchain_config")
load("@local_config_platform//:constraints.bzl", "HOST_CONSTRAINTS")

package(default_visibility = ["//visibility:public"])

TARGET_CPUS = [
    "aarch64",
    "x86_64",
]

filegroup(
    name = "empty",
)

filegroup(
    name = "cc-compiler-prebuilts",
    srcs = [
        "//:bin/clang",
        "//:bin/clang-15",
        "//:bin/llvm-ar",
        "//:bin/clang++",
        "//:bin/ld.lld",
        "//:bin/lld",
        "//:bin/llvm-nm",
        "//:bin/llvm-objdump",
        "//:bin/llvm-strip",
        "//:bin/llvm-objcopy",
    ] + glob([
        # TODO(fxbug.dev/91180): Try not to hard code this path.
        "lib/clang/15.0.0/include/**",
    ]) + glob([
        "include/c++/v1/**",
    ]),
)

filegroup(
    name = "compile",
    srcs = [
        ":cc-compiler-prebuilts",
    ],
)

filegroup(
    name = "objcopy",
    srcs = [
        "//:bin/llvm-objcopy",
    ],
)
[
    filegroup(
        name = "every-file-" + cpu,
        srcs = [
            ":cc-compiler-prebuilts",
            ":runtime-" + cpu,
        ],
    )
    for cpu in TARGET_CPUS
]
[
    filegroup(
        name = "link-" + cpu,
        srcs = [
            ":cc-compiler-prebuilts",
            ":runtime-" + cpu,
        ],
    )
    for cpu in TARGET_CPUS
]
[
    filegroup(
        name = "runtime-" + cpu,
        srcs = [
            # TODO(fxbug.dev/91180): Don't hard code this path.
            "//:lib/clang/14.0.0/lib/" + cpu + "-unknown-fuchsia/libclang_rt.builtins.a",
        ],
    )
    for cpu in TARGET_CPUS
]
[
    cc_toolchain_config(
        name = "crosstool-1.x.x-llvm-fuchsia-config-" + cpu,
        cpu = cpu,
    )
    for cpu in TARGET_CPUS
]
[
    cc_toolchain(
        name = "cc-compiler-" + cpu,
        all_files = ":every-file-" + cpu,
        ar_files = ":compile",
        compiler_files = ":compile",
        dwp_files = ":empty",
        dynamic_runtime_lib = ":runtime-" + cpu,
        linker_files = ":link-" + cpu,
        objcopy_files = ":objcopy",
        static_runtime_lib = ":runtime-" + cpu,
        strip_files = ":runtime-" + cpu,
        supports_param_files = 1,
        toolchain_config = "crosstool-1.x.x-llvm-fuchsia-config-" + cpu,
        toolchain_identifier = "crosstool-1.x.x-llvm-fuchsia-" + cpu,
    )
    for cpu in TARGET_CPUS
]
cc_library(
    name = "sources",
    srcs = glob(["src/**"]),
    visibility = ["//visibility:public"],
)
[
    filegroup(
        name = "dist-" + cpu,
        srcs = [
            "//:lib/" + cpu + "-unknown-fuchsia/libc++.so.2",
            "//:lib/" + cpu + "-unknown-fuchsia/libc++abi.so.1",
            "//:lib/" + cpu + "-unknown-fuchsia/libunwind.so.1",
        ],
    )
    for cpu in TARGET_CPUS
]

constraint_value(
    name = "fuchsia",
    constraint_setting = "@platforms//os:os",
)

FUCHSIA_PLATFORM = [
  ":fuchsia",
  "@platforms//cpu:aarch64",
]

platform(
    name = "fuchsia_aarch64",
    constraint_values = FUCHSIA_PLATFORM,
)

toolchain(
    name = "fuchsia-cc-toolchain-aarch64",
    exec_compatible_with = HOST_CONSTRAINTS,
    target_compatible_with = FUCHSIA_PLATFORM,
    toolchain = ":cc-compiler-aarch64",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
