load(
    "@rules_fuchsia//fuchsia:defs.bzl",
    "fuchsia_select",
)

# Note: the cc_library / cc_import combo serves two purposes:
#  - it allows the use of a select clause to target the proper architecture;
#  - it works around an issue with cc_import which does not have an "includes"
#    nor a "deps" attribute.
cc_library(
    name = "{{name}}",
    hdrs = [
        {{headers}}
    ],
    deps = {{prebuilt_select}} + [ {{deps}} ],
    strip_include_prefix = "{{relative_include_dir}}",
    data = {{dist_select}},
)

# TODO(mangini): parse data atoms to add explicit export clauses instead of using glob.
# Currently this cannot be done because data and cc_prebuilt_library are two atoms
# with the same base directory in the metadata, but only one BUILD.bazel is generated
# from a template, so adding data as a template would overwrite this
# cc_prebuilt_library generated BUILD.bazel or vice-versa.
exports_files(
    glob(["**/*.cml", "**/*.cmx"]),
)
