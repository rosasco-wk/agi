load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@gapid//tools/build/rules:repository.bzl", "maybe_repository")


def _fuchsia_idk_repository_impl(ctx):
  idk_home = ctx.os.environ.get("FUCHSIA_IDK_HOME")
  if idk_home == None:
    fail("FUCHSIA_IDK_HOME env var is required")
  ctx.symlink(idk_home, "idk")
  ctx.symlink(Label("@gapid//tools/build/fuchsia:idk.BUILD"), "BUILD.bazel")

fuchsia_idk_repository = repository_rule(
  implementation = _fuchsia_idk_repository_impl,
  environ = ["FUCHSIA_IDK_HOME"],
)


_CIPD_URL = "https://chrome-infra-packages.appspot.com/dl/{}/{}/+/{}"

def _fuchsia_clang_repository_impl(ctx):
  ctx.download_and_extract(_CIPD_URL.format(
      "fuchsia/third_party/clang",
      "linux-amd64",
      "git_revision:02e7479e6bd36ab1b3124fff76302f125d96b176"
    ),
    sha256 = "d8770e4f595dbcd092f0db65773ce3cb0ae2d82ef816bc680d918838e7e5db87",
    type = "zip",
  )
  ctx.symlink(Label("@gapid//tools/build/fuchsia:crosstool.BUILD"), "BUILD.bazel")

  idk_root = str(ctx.path(Label("@fuchsia_idk//:idk/README.md")).dirname)
  sysroot_arm64 = idk_root + "/arch/arm64/sysroot"
  sysroot_x64 = idk_root + "/arch/x64/sysroot"

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
    fuchsia_idk_repository,
    name = "fuchsia_idk",
    locals = locals,
  )
  maybe_repository(
    fuchsia_clang_repository,
    name = "fuchsia_clang",
    locals = locals,
  )
  native.register_toolchains("@fuchsia_clang//:toolchain")
