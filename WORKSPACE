QT_BUILD_FILE_CONTENT = """
package(default_visibility = [ "//visibility:public" ])
exports_files([
  "bin/rcc",
])
"""

new_local_repository(
    name = "qt",
    path = "/home/john/Qt/5.10.1/gcc_64",
    build_file_content = QT_BUILD_FILE_CONTENT,
)
