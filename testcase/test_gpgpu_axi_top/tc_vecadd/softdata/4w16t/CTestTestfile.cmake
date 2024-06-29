# CMake generated Testfile for 
# Source directory: /data/eda/work/yangzx/ventus/pocl/examples/vecadd
# Build directory: /data/eda/work/yangzx/ventus/pocl/build/examples/vecadd
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(examples/vecadd "/data/eda/work/yangzx/ventus/pocl/build/examples/vecadd/vecadd")
set_tests_properties(examples/vecadd PROPERTIES  COST "3.0" DEPENDS "pocl_version_check" LABELS "internal;vulkan" PASS_REGULAR_EXPRESSION "OK" PROCESSORS "1" _BACKTRACE_TRIPLES "/data/eda/work/yangzx/ventus/pocl/examples/vecadd/CMakeLists.txt;39;add_test;/data/eda/work/yangzx/ventus/pocl/examples/vecadd/CMakeLists.txt;0;")
add_test(examples/vecadd_large_grid "/data/eda/work/yangzx/ventus/pocl/build/examples/vecadd/vecadd" "128000" "128" "10000" "100" "1" "1")
set_tests_properties(examples/vecadd_large_grid PROPERTIES  COST "3.0" DEPENDS "pocl_version_check" LABELS "internal;vulkan" PASS_REGULAR_EXPRESSION "OK" PROCESSORS "1" _BACKTRACE_TRIPLES "/data/eda/work/yangzx/ventus/pocl/examples/vecadd/CMakeLists.txt;41;add_test;/data/eda/work/yangzx/ventus/pocl/examples/vecadd/CMakeLists.txt;0;")
