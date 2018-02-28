def _build_qrc_impl(ctx):
    content = ['<RCC>', '<qresource prefix="%s">' % ctx.label.name, ]
    content += ['<file>%s</file>' % f.path for f in ctx.files.srcs]
    content += ['</qresource>', '</RCC>', ]
    ctx.actions.write(
        output = ctx.outputs.qrc,
        content = '\n'.join(content),
    )
    # The executable output is added automatically to this target.
    runfiles = ctx.runfiles(collect_data=True, collect_default=True)
    print(runfiles.files)
    return [DefaultInfo(runfiles=runfiles)]

build_qrc = rule(
    implementation=_build_qrc_impl,
    executable=False,
    output_to_genfiles=True,
    attrs={
        "srcs": attr.label_list(cfg="data", allow_files=True),
    },
    outputs={
        "qrc": "%{name}.qrc",
    }
)

def _build_rcc_cpp_impl(ctx):
    args = ctx.actions.args()
    args.add('-o')
    args.add(ctx.outputs.cpp.short_path)
    args.add(ctx.files.srcs)

    ctx.actions.run(
        inputs=ctx.files.srcs,
        outputs = [ctx.outputs.cpp],
        arguments = [args],
        executable = ctx.executable._qt_rcc,
        #input_manifests = ,
    )
    #print(ctx.attr.srcs[0][DefaultInfo].data_runfiles.files)
    #runfiles = ctx.runfiles(runfiles = ctx.attr.srcs[0][DefaultInfo].data_runfiles.files)
    #return [DefaultInfo(runfiles=ctx.runfiles(files=ctx.files.data, collect_default=True))]
    runfiles = ctx.runfiles(files=ctx.files.srcs, collect_data=True, collect_default=True)
    print(runfiles.files)
    return [DefaultInfo(runfiles=runfiles)]

build_rcc_cpp = rule(
    implementation = _build_rcc_cpp_impl,
    executable = False,
    output_to_genfiles = True,
    attrs = {
        "srcs": attr.label_list(allow_files=True),
        "deps": attr.label_list(allow_files=True),
        "_qt_rcc": attr.label(
            default = Label("@qt//:bin/rcc"),
            executable = True,
            cfg = "host",
            allow_files=True
        ),
    },
    outputs = {
        "cpp": "%{name}.cpp",
    }
)

def gen_cpp(name, srcs):
    build_qrc(
        name = name + "_rc",
        srcs = srcs,
    )

    build_rcc_cpp(
        name = name, #+ "_cpp",
        srcs = [name + "_rc"],
        deps = srcs,
    )

