cmake_minimum_required(VERSION 3.20.0)

set(CONFIG_COMPILER_WARNINGS_AS_ERRORS n)

set(ZTEST_BUILD_EXT_BASE ${CMAKE_CURRENT_LIST_DIR})

include(cmake/config_test.cmake)
include(cmake/packages.cmake)