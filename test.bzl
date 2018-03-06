def _wrapper_impl(ctx):
    rcc = ctx.expand_location(
        '$(location @qt//:bin/rcc)',
        ctx.attr.data + [ctx.attr._qt_rcc],
    )
    print(rcc)
    print(ctx.executable._qt_rcc.short_path)
    print(ctx.attr._qt_rcc)
    print(ctx.attr.data[0].label)

    content = ['<RCC>', '<qresource prefix="%s">' % ctx.label.name, ]
    content += ['<file>%s</file>' % f.short_path for f in ctx.files.data]
    content += ['</qresource>', '</RCC>', ]
    ctx.actions.write(
        output = ctx.outputs.qrc,
        content = '\n'.join(content),
    )

    dat1 = ctx.expand_location(
        '$(location %s)' % ctx.attr.data[0].label,
        ctx.attr.data
    )

    #qrc = ctx.expand_location(
        #'$(location %s)' % ctx.outputs.qrc,
        #[ctx.outputs.qrc],
    #)
    #print(qrc)
    qrc = ctx.outputs.qrc.short_path

    content = [
        '#!/bin/bash',
        'echo PWD=$(pwd)',
        'find .',
        '%s %s -o "$@"' % (rcc, qrc),
        'ls "$@"',
    ]
    ctx.file_action(
        output=ctx.outputs.executable,
        #content='ls ' + rcc + ' && ls ' + dat1,
        content='\n'.join(content),
        executable=True
    )

    runfiles = ctx.runfiles(
        collect_data=True,
        collect_default=True,
        files=[ctx.executable._qt_rcc, ctx.outputs.qrc],
    )
    return [DefaultInfo(runfiles=runfiles)]

wrapper = rule(
    implementation=_wrapper_impl,
    executable=True,
    attrs={
        "data": attr.label_list(cfg="data", allow_files=True),
        "_qt_rcc": attr.label(
            default = Label("@qt//:bin/rcc"),
            executable = True,
            cfg = "host",
            allow_files=True
        ),
    },
    outputs={
        "qrc": "%{name}.qrc",
    }
)

def _build_cpp_impl(ctx):
    tool_inputs, _, input_manifests = ctx.resolve_command(
        tools=[ctx.attr.wrapper],
        #execution_requirements = {'no-sandbox': 'True'},
    )

    ctx.actions.run(
        inputs=tool_inputs,
        outputs = [ctx.outputs.cpp],
        arguments = [ctx.outputs.cpp.short_path],
        executable = ctx.executable.wrapper,
        input_manifests = input_manifests,
    )

    runfiles = ctx.runfiles(
        files=tool_inputs,
        collect_data=True,
        collect_default=True
    )
    return [DefaultInfo(runfiles=runfiles)]


build_cpp = rule(
    implementation = _build_cpp_impl,
    executable = False,
    attrs = {
        "wrapper": attr.label(
            executable = True,
            cfg = "host",
            allow_files = True,
        )
    },
    outputs = {
        "cpp": "%{name}.cpp",
    }
)

def gen_cpp(name, data):
    wrapper(name = name + "_base", data = data)

    tool = name + "_base"

    build_cpp(name = name, wrapper = tool)

    #native.genrule(
    #    name = name,
    #    srcs = data,
    #    outs = ["%s.cpp" % name],
    #    cmd = '$(location :%s) "$@"' % tool,
    #    tools = [tool],
    #)

