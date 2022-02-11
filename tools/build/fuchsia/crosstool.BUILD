load(":cc_toolchain_config.bzl", "cc_toolchain_config")

package(default_visibility = ["//visibility:public"])

cc_toolchain_suite(
    name = "toolchain",
    toolchains = {
        "aarch64|llvm": ":cc-compiler-aarch64",
        "aarch64": ":cc-compiler-aarch64",
        "x86_64|llvm": ":cc-compiler-x86_64",
        "x86_64": ":cc-compiler-x86_64",
    },
)

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
        "//:bin/clang-14",
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
        "lib/clang/14.0.0/include/**",
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
alias(
    name = "dist",
    actual = select({
        ":arm_build": ":dist-aarch64",
        ":x86_build": ":dist-x86_64",
    }),
)
config_setting(
    name = "arm_build",
    values = {"cpu": "aarch64"},
)
config_setting(
    name = "x86_build",
    values = {"cpu": "x86_64"},
)
