load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@gapid//tools/build/rules:repository.bzl", "maybe_repository")
load("@gapid//tools/build/fuchsia/private:fuchsia_toolchain_info.bzl", "fuchsia_toolchain_info")


# The Fuchsia SDK core must be downloaded in advance to
# FUCHSIA_SDK_CORE_HOME for this function to work properly.
def _fuchsia_sdk_core_repository_impl(ctx):
  sdk_core_home = ctx.os.environ.get("FUCHSIA_SDK_CORE_HOME")
  if sdk_core_home == None:
    fail("FUCHSIA_SDK_CORE_HOME env var is required")
  if not ctx.path(sdk_core_home).exists:
    fail("FUCHSIA_SDK_CORE_HOME directory does not exist")
  ctx.symlink(sdk_core_home, "sdk_core")
  ctx.symlink(Label("@gapid//tools/build/fuchsia:sdk_core.BUILD"), "BUILD.bazel")

fuchsia_sdk_core_repository = repository_rule(
  implementation = _fuchsia_sdk_core_repository_impl,
  environ = ["FUCHSIA_SDK_CORE_HOME"],
)


_CIPD_URL = "https://chrome-infra-packages.appspot.com/dl/{}/{}/+/{}"

def _fuchsia_clang_repository_impl(ctx):
  # Download clang.
  ctx.download_and_extract(_CIPD_URL.format(
      "fuchsia/third_party/clang",
      "linux-amd64",
      "git_revision:02e7479e6bd36ab1b3124fff76302f125d96b176"
    ),
    sha256 = "d8770e4f595dbcd092f0db65773ce3cb0ae2d82ef816bc680d918838e7e5db87",
    type = "zip",
  )
  # Symlink toolchain setup file.
  ctx.symlink(Label("@gapid//tools/build/fuchsia:crosstool.BUILD"), "BUILD.bazel")

  sdk_core_root = str(ctx.path(Label("@fuchsia_sdk_core//:sdk_core/README.md")).dirname)
  sysroot_arm64 = sdk_core_root + "/arch/arm64/sysroot"
  sysroot_x64 = sdk_core_root + "/arch/x64/sysroot"

  ctx.template(
    "cc_toolchain_config.bzl",
    Label("@//tools/build/fuchsia:toolchain_config_template.bzl"),
    substitutions = {
      "%{SYSROOT_aarch64}": sysroot_arm64,
      "%{SYSROOT_x86_64}": sysroot_x64,
      "%{CROSSTOOL_ROOT}": str(ctx.path(".")),
    },
  )


fuchsia_clang_repository = repository_rule(
  implementation = _fuchsia_clang_repository_impl,
)

def fuchsia_dependencies(locals = {}):
  maybe_repository(
    fuchsia_sdk_core_repository,
    name = "fuchsia_sdk_core",
    locals = locals,
  )
  maybe_repository(
    fuchsia_clang_repository,
    name = "fuchsia_clang",
    locals = locals,
  )
  native.register_toolchains("@fuchsia_clang//:cc-compiler-aarch64")
