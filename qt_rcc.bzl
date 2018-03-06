def _qrc_wrapper_impl(ctx):
    """Creates a .qrc file as well as an executable wrapper script for rcc
    """
    qrc = ctx.outputs.qrc.short_path
    rcc = ctx.executable._qt_rcc.path

    # Write the .qrc file
    run_deps = []
    qrc_content = ['<RCC>']
    for (target, prefix) in ctx.attr.data.items():
        run_deps += [target.files]
        qrc_content += ['  <qresource prefix = "%s">' % prefix]
        qrc_content += ['    <file>%s</file>' % file.short_path for file in target.files.to_list()]
        qrc_content += ['  </qresource>']
    qrc_content += ['</RCC>']
    ctx.actions.write(
        output = ctx.outputs.qrc,
        content = '\n'.join(qrc_content),
    )

    # Write the executable wrapper script
    wrapper_content = [
        '#!/bin/bash',
        'RUNFILES=${BASH_SOURCE[0]}.runfiles/__main__',
        '$RUNFILES/%s $RUNFILES/%s -o "$@"' % (rcc, qrc),
    ]
    ctx.file_action(
        output = ctx.outputs.executable,
        content = '\n'.join(wrapper_content),
        executable = True
    )

    # Collect and return runfiles
    runfiles = ctx.runfiles(
        collect_data = True,
        collect_default = True,
        files = [ctx.executable._qt_rcc, ctx.outputs.qrc],
        transitive_files = depset(transitive = run_deps),

    )
    return [DefaultInfo(runfiles = runfiles)]

_qrc_wrapper = rule(
    implementation = _qrc_wrapper_impl,
    executable = True,
    attrs = {
        "data": attr.label_keyed_string_dict(
            allow_files = True,
            cfg = "data",
        ),
        "_qt_rcc": attr.label(
            default = Label("@qt//:bin/rcc"),
            executable = True,
            cfg = "host",
            allow_files = True
        ),
    },
    outputs = {
        "qrc": "%{name}.qrc",
    }
)

def _rcc_cpp_impl(ctx):
    """Creates a .cpp file using the previously generated wrapper and .qrc
    """
    tool_inputs, _, input_manifests = ctx.resolve_command(
        tools = [ctx.attr.wrapper],
    )

    ctx.actions.run(
        inputs = tool_inputs,
        outputs = [ctx.outputs.cpp],
        arguments = [ctx.outputs.cpp.path],
        executable = ctx.executable.wrapper,
        input_manifests = input_manifests,
    )

    runfiles = ctx.runfiles(
        files = tool_inputs,
        collect_data = True,
        collect_default = True
    )
    return [DefaultInfo(runfiles = runfiles)]


_rcc_cpp = rule(
    implementation = _rcc_cpp_impl,
    executable = False,
    output_to_genfiles = True,
    attrs = {
        "wrapper": attr.label(
            executable = True,
            cfg = "host",
            allow_files = True,
        )
    },
    outputs = {
        "cpp": "%{name}_rc.cpp",
    }
)

def rcc_cpp(name, data):
    """Generate a 'name_rcc.cpp' file containing binary resource data from
    multiple sources using the Qt Resource Compiler (rcc).

    See: http://doc.qt.io/qt-5/resources.html
    Example usage:

        filegroup(
            name = "test_group",
            srcs = [ "data/my.file", "data/my.file2", ]
        )

        rcc_cpp(
            name = "test_rcc",
            data = {
                ":test_data": "/resource/prefix",
                "data/my.file3": "/my/other/prefix",
            }
        )

        cc_library(
            name = "test",
            srcs = [":test_rcc"]
        )
    """
    base = name + "_wrapper"
    _qrc_wrapper(name = base, data = data)
    _rcc_cpp(name = name, wrapper = base)

