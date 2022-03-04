"""Implementation of cc_bind_rules rule"""

load(":fuchsia_bind_library.bzl", "BindFilesInfo")

def _process_bindc_args(context):
    # Collect all the bind files and their filepaths that will be passed to bindc.
    inputs = []
    include_filepaths = []

    for dep in context.attr.deps:
        trans_srcs = dep[BindFilesInfo].transitive_sources
        for src in trans_srcs.to_list():
            # Only add unique instances.
            if src.path in include_filepaths:
                continue
            inputs.append(src)
            if len(include_filepaths) == 0:
                include_filepaths.append("--include")

            include_filepaths.append(src.path)

    files_argument = []
    for file in context.files.rules:
        inputs.append(file)
        files_argument.append(file.path)
    return {
        "inputs": inputs,
        "files_argument": files_argument,
        "include_filepaths": include_filepaths,
    }

def _bind_rules_header_impl(context):
    args = _process_bindc_args(context)
    sdk = context.toolchains["@rules_fuchsia//fuchsia:toolchain"]
    context.actions.run(
        executable = sdk.bindc,
        arguments = [
                        "compile",
                    ] + args["include_filepaths"] +
                    [
                        "--output",
                        context.outputs.output.path,
                    ] + args["files_argument"],
        inputs = args["inputs"],
        outputs = [
            context.outputs.output,
        ],
        mnemonic = "Bindcheader",
    )

def _driver_bytecode_bind_rules_impl(context):
    args = _process_bindc_args(context)
    sdk = context.toolchains["@rules_fuchsia//fuchsia:toolchain"]
    context.actions.run(
        executable = sdk.bindc,
        arguments = [
                        "compile",
                        "--output-bytecode",
                        "--use-new-bytecode",
                    ] + args["include_filepaths"] +
                    [
                        "--output",
                        context.outputs.output.path,
                    ] + args["files_argument"],
        inputs = args["inputs"],
        outputs = [
            context.outputs.output,
        ],
        mnemonic = "Bindcbc",
    )

_bind_rules_header = rule(
    implementation = _bind_rules_header_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    output_to_genfiles = True,
    attrs = {
        "rules": attr.label(
            doc = "Path to the bind rules source file",
            mandatory = True,
            allow_single_file = True,
        ),
        "output": attr.output(
            mandatory = True,
        ),
        "deps": attr.label_list(
            doc = "The list of libraries this library depends on",
            mandatory = False,
            providers = [BindFilesInfo],
        ),
    },
)

fuchsia_driver_bytecode_bind_rules = rule(
    implementation = _driver_bytecode_bind_rules_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    attrs = {
        "rules": attr.label(
            doc = "Path to the bind rules source file",
            mandatory = True,
            allow_single_file = True,
        ),
        "output": attr.output(
            mandatory = True,
        ),
        "deps": attr.label_list(
            doc = "The list of libraries this library depends on",
            mandatory = False,
            providers = [BindFilesInfo],
        ),
    },
)

def fuchsia_driver_header_bind_rules(name, rules, output = None, deps = None, tags = None, **kwargs):
    """Generates cc_library() for the given bind rules.

    Args:
      name: Target name. Required.
      rules: Bind rules file. Required.
      output: Name of generated header file. Defaults to name + ".h".
      deps: Additional dependencies.
      tags: Optional tags.
      **kwargs: Remaining args.
    """

    if not output:
        output = "%s.h" % name
    gen_name = "%s_gen" % name

    _bind_rules_header(
        name = gen_name,
        output = output,
        rules = rules,
        deps = deps,
        visibility = ["//visibility:private"],
    )

    native.cc_library(
        tags = tags,
        name = name,
        hdrs = [
            ":%s" % gen_name,
        ],
        **kwargs
    )
