# Copyright 2021 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load(":providers.bzl", "FuchsiaComponentInfo", "FuchsiaPackageResourceGroupInfo", "FuchsiaPackageResourceInfo")

def _fuchsia_component_impl(ctx):
    component_name = ctx.attr.component_name or ctx.label.name
    manifest = ctx.file.manifest

    resources = []
    for dep in ctx.attr.deps:
        if FuchsiaPackageResourceInfo in dep:
            resources.append(dep[FuchsiaPackageResourceInfo])
        elif FuchsiaPackageResourceGroupInfo in dep:
            for r in dep[FuchsiaPackageResourceGroupInfo].resources:
                resources.append(r)
        elif DefaultInfo in dep:
            for mapping in dep[DefaultInfo].data_runfiles.root_symlinks.to_list():
                resources.append(FuchsiaPackageResourceInfo(src = mapping.target_file, dest = mapping.path))

            for f in dep[DefaultInfo].files.to_list():
                resources.append(FuchsiaPackageResourceInfo(src = f, dest = f.short_path))

    for src, dest in ctx.attr.content.items():
        if DefaultInfo in src:
            files_list = src[DefaultInfo].files.to_list()
            if not dest.endswith("/") and len(files_list) > 1:
                fail("To map multiple files in %s, the content mapping %s should end with a slash to indicate a directory." % (ctx.label.name, dest))

            if dest.startswith("/"):
                # pkgctl does not play well with paths starting with "/"
                dest = dest[1:]

            for f in files_list:
                d = dest
                if dest.endswith("/"):
                    d = d + f.basename

                resources.append(FuchsiaPackageResourceInfo(src = f, dest = d))

    return [
        FuchsiaComponentInfo(
            name = component_name,
            manifest = manifest,
            resources = resources,
        ),
    ]

fuchsia_component = rule(
    doc = """Creates a Fuchsia component which can be added to a package

This rule will take a component manifest and compile it into a form that
is suitable to be included in a package. The component can include any
number of dependencies which will be included in the final package.
""",
    implementation = _fuchsia_component_impl,
    attrs = {
        "deps": attr.label_list(
            doc = "The list of dependencies this component depends on",
        ),
        "content": attr.label_keyed_string_dict(
            doc = """A map of dependencies and their destination in the Fuchsia component.
                     If a destination ends with a slash, it is assumed to be a directory""",
            mandatory = False,
        ),
        "manifest": attr.label(
            doc = "The component manifest file",
            allow_single_file = [".cm", ".cmx"],
            mandatory = True,
        ),
        "component_name": attr.string(
            doc = "The name of the package, defaults to the rule name",
        ),
    },
)

def _fuchsia_component_manifest_impl(ctx):
    sdk = ctx.toolchains["@rules_fuchsia//fuchsia:toolchain"]
    if not ctx.file.src and not ctx.attr.content:
        fail("Either 'src' or 'content' needs to be specified.")

    if ctx.file.src and ctx.attr.content:
        fail("Only one of 'src' and 'content' can be specified.")

    if ctx.file.src:
        manifest_in = ctx.file.src
    else:
        # create a manifest file from the given content
        if not ctx.attr.component_name:
            fail("Attribute 'component_name' has to be specified when using inline content.")

        manifest_in = ctx.actions.declare_file("%s.cml" % ctx.attr.component_name)
        ctx.actions.write(
            output = manifest_in,
            content = ctx.attr.content,
            is_executable = False,
        )

    # output should have the .cm extension
    manifest_out = ctx.actions.declare_file(manifest_in.basename[:-1])

    # use a dict to eliminate workspace root duplicates
    include_root_dict = {}
    for i in ctx.files.includes:
        include_root_dict[i.owner.workspace_root] = 1

    include_root = []
    for w in include_root_dict.keys():
        include_root.extend(["--includeroot", w])

    ctx.actions.run(
        executable = sdk.cmc,
        arguments = [
            "compile",
            "--output",
            manifest_out.path,
            manifest_in.path,
            "--includepath",
            manifest_in.path[:-len(manifest_in.basename)],
        ] + include_root,
        inputs = [manifest_in] + ctx.files.includes,
        outputs = [
            manifest_out,
        ],
        mnemonic = "CmcCompile",
    )

    return [
        DefaultInfo(files = depset([manifest_out])),
    ]

fuchsia_component_manifest = rule(
    doc = """Compiles a component manifest from a input file.

This rule will compile an input cml file and output a cm file. The file can,
optionally, include additional cml files but they must be relative to the
src file and included in the includes attribute.

```
{
    include: ["foo.cml", "some_dir/bar.cml"]
}
```
""",
    implementation = _fuchsia_component_manifest_impl,
    toolchains = ["@rules_fuchsia//fuchsia:toolchain"],
    attrs = {
        "src": attr.label(
            doc = "The source manifest to compile",
            allow_single_file = [".cml"],
        ),
        "content": attr.string(
            doc = "Inline content for the manifest",
        ),
        "component_name": attr.string(
            doc = "Name of the component for inline manifests",
        ),
        "includes": attr.label_list(
            doc = "A list of dependencies which are included in the src cml",
            allow_files = [".cml"],
        ),
    },
)
