load(
    "@rules_fuchsia//fuchsia:defs.bzl",
    "fuchsia_fidl_library",
    "fuchsia_fidl_hlcpp_library",
    "fuchsia_fidl_llcpp_library",
    "fuchsia_banjo_cc_library",
)

fuchsia_fidl_library(
    name = "{{name}}",
    library = "{{name}}",
    deps = [
        {{deps}}
    ],
    srcs = [
        {{sources}}
    ],
)

fuchsia_fidl_hlcpp_library(
    name = "{{name}}_cc",
    library = ":{{name}}",
    deps = [
        "//pkg/fidl_cpp",
        {{cc_deps}}
    ],
)

fuchsia_fidl_llcpp_library(
    name = "{{name}}_llcpp_cc",
    library = ":{{name}}",
    deps = [
        "//pkg/fidl-llcpp-experimental-driver-only",
        {{llcpp_deps}}
    ],
)

fuchsia_banjo_cc_library(
    name = "{{name}}_banjo_cc",
    library = ":{{name}}",
    deps = [
        {{banjo_deps}}
    ],
)