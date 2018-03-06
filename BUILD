#load("//:test2.bzl", "gen_cpp")
load("//:test.bzl", "gen_cpp")

filegroup(
    name = "test_data",
    srcs = [
        "data/my.file",
        "data/my.file2",
    ]
)

gen_cpp(
    name = "test",
    #srcs=[":test_data"]
    data = [
        "data/my.file",
        "data/my.file2",
    ]
)
