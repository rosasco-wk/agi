"""Implementation of bind_library rule"""

# A Bind library.
#
# Parameters
#
#   srcs
#     List of source files.
#
#   deps
#     List of other bind_library targets included by the library.

BindFilesInfo = provider(
    "A depset containing the sources and transitive deps of the bind library",
    fields = ["transitive_sources"],
)

def _get_transitive_srcs(srcs, deps):
    return depset(
        srcs,
        transitive = [dep[BindFilesInfo].transitive_sources for dep in deps],
    )

def _bind_library_impl(context):
    trans_srcs = _get_transitive_srcs(context.files.srcs, context.attr.deps)
    return [
        BindFilesInfo(transitive_sources = trans_srcs),
    ]

fuchsia_bind_library = rule(
    implementation = _bind_library_impl,
    attrs = {
        "srcs": attr.label_list(
            doc = "The list of bind library source files",
            mandatory = True,
            allow_files = True,
            allow_empty = False,
        ),
        "deps": attr.label_list(
            doc = "The list of bind libraries this library depends on",
            mandatory = False,
            providers = [BindFilesInfo],
        ),
    },
)
