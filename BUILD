load("//:qt_rcc.bzl", "rcc_cpp")

filegroup(
    name = "test_data",
    srcs = [
        "data/my.file",
        "data/my.file2",
    ]
)

rcc_cpp(
    name = "test",
    data = {
        #"test2.bzl": "prefix1",
        ":test_data": "prefix1",
    }
)

cc_library(
    name = "test_bin",
    srcs = [":test"],
)

