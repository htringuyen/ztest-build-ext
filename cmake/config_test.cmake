# SPDX-License-Identifier: Apache-2.0

include_guard(GLOBAL)

cmake_minimum_required(VERSION 3.20.0)

set(M64_MODE TRUE)

set(ZEPHYR_CMAKE_MODULES_DIR "${ZEPHYR_BASE}/cmake/modules")

include(${ZEPHYR_CMAKE_MODULES_DIR}/extensions.cmake)
include(${ZEPHYR_CMAKE_MODULES_DIR}/yaml.cmake)
include(${ZEPHYR_CMAKE_MODULES_DIR}/root.cmake)
include(${ZEPHYR_CMAKE_MODULES_DIR}/boards.cmake)
include(${ZEPHYR_CMAKE_MODULES_DIR}/hwm_v2.cmake)
include(${ZEPHYR_CMAKE_MODULES_DIR}/configuration_files.cmake)

include(${ZEPHYR_CMAKE_MODULES_DIR}/kconfig.cmake)
include(${ZEPHYR_CMAKE_MODULES_DIR}/arch.cmake)
include(${ZEPHYR_CMAKE_MODULES_DIR}/soc.cmake)

find_package(TargetTools)

enable_language(C CXX ASM)

include(${ZEPHYR_BASE}/cmake/target_toolchain_flags.cmake)

# Parameters:
#   SOURCES: list of source files, default main.c
#   INCLUDE: list of additional include paths relative to ZEPHYR_BASE

foreach(extra_flags EXTRA_CPPFLAGS EXTRA_LDFLAGS EXTRA_CFLAGS EXTRA_CXXFLAGS EXTRA_AFLAGS)
  list(LENGTH ${extra_flags} flags_length)
  if(flags_length LESS_EQUAL 1)
    # A length of zero means no argument.
    # A length of one means a single argument or a space separated list was provided.
    # In both cases, it is safe to do a separate_arguments on the argument.
    separate_arguments(${extra_flags}_AS_LIST UNIX_COMMAND ${${extra_flags}})
  else()
    # Already a proper list, no conversion needed.
    set(${extra_flags}_AS_LIST "${${extra_flags}}")
  endif()
endforeach()

set(ENV_ZEPHYR_BASE $ENV{ZEPHYR_BASE})
# This add support for old style boilerplate include.
if((NOT DEFINED ZEPHYR_BASE) AND (DEFINED ENV_ZEPHYR_BASE))
  set(ZEPHYR_BASE ${ENV_ZEPHYR_BASE} CACHE PATH "Zephyr base")
endif()

find_package(Deprecated COMPONENTS SOURCES)

if(NOT SOURCES AND EXISTS main.c)
  set(SOURCES main.c)
endif()

add_library(test_interface INTERFACE)
target_link_libraries(app PRIVATE test_interface)

set(KOBJ_TYPES_H_TARGET kobj_types_h_target)
include(${ZEPHYR_BASE}/cmake/kobj.cmake)
add_dependencies(test_interface ${KOBJ_TYPES_H_TARGET})
gen_kobject_list_headers(GEN_DIR_OUT_VAR KOBJ_GEN_DIR)

# Generates empty header files to build
set(INCL_GENERATED_DIR ${APPLICATION_BINARY_DIR}/zephyr/include/generated/zephyr)
set(INCL_GENERATED_SYSCALL_DIR ${INCL_GENERATED_DIR}/syscalls)
list(APPEND INCL_GENERATED_HEADERS
  ${INCL_GENERATED_DIR}/devicetree_generated.h
  ${INCL_GENERATED_DIR}/offsets.h
  ${INCL_GENERATED_DIR}/syscall_list.h
  ${INCL_GENERATED_DIR}/syscall_macros.h
  ${INCL_GENERATED_SYSCALL_DIR}/kernel.h
  ${INCL_GENERATED_SYSCALL_DIR}/kobject.h
  ${INCL_GENERATED_SYSCALL_DIR}/log_core.h
  ${INCL_GENERATED_SYSCALL_DIR}/log_ctrl.h
  ${INCL_GENERATED_SYSCALL_DIR}/log_msg.h
  ${INCL_GENERATED_SYSCALL_DIR}/sys_clock.h
)

file(MAKE_DIRECTORY ${INCL_GENERATED_SYSCALL_DIR})
foreach(header ${INCL_GENERATED_HEADERS})
  file(TOUCH ${header})
endforeach()

list(APPEND INCLUDE
  subsys/testsuite/ztest/include/zephyr
  subsys/testsuite/ztest/unittest/include
  subsys/testsuite/include/zephyr
  subsys/testsuite/ztest/include
  subsys/testsuite/include
  include/zephyr
  include
  .
)

if(CMAKE_HOST_APPLE)
else()

if(M64_MODE)
set (CMAKE_C_FLAGS "-m64")
set (CMAKE_CXX_FLAGS "-m64")
else()
set (CMAKE_C_FLAGS "-m32") #deprecated on macOS
set (CMAKE_CXX_FLAGS "-m32") #deprecated on macOS
endif(M64_MODE)

endif()

add_compile_definitions(ARCH_STACK_PTR_ALIGN=8)

target_compile_options(test_interface INTERFACE
  -imacros ${AUTOCONF_H}
  -Wall
  -I ${KOBJ_GEN_DIR}
  ${EXTRA_CPPFLAGS_AS_LIST}
  ${EXTRA_CFLAGS_AS_LIST}
  $<$<COMPILE_LANGUAGE:CXX>:${EXTRA_CXXFLAGS_AS_LIST}>
  $<$<COMPILE_LANGUAGE:ASM>:${EXTRA_AFLAGS_AS_LIST}>
  -Wno-format-zero-length
  )

target_link_options(app PRIVATE
  -T "${ZEPHYR_BASE}/subsys/testsuite/include/zephyr/ztest_unittest.ld"
  )

target_link_libraries(app PRIVATE
  ${EXTRA_LDFLAGS_AS_LIST}
  )

target_compile_options(test_interface INTERFACE $<TARGET_PROPERTY:compiler,debug>)

if(CONFIG_COVERAGE)
  target_compile_options(test_interface INTERFACE $<TARGET_PROPERTY:compiler,coverage>)

  target_link_libraries(app PRIVATE $<TARGET_PROPERTY:linker,coverage>)
endif()

if (CONFIG_COMPILER_WARNINGS_AS_ERRORS)
  target_compile_options(test_interface INTERFACE $<TARGET_PROPERTY:compiler,warnings_as_errors>)
endif()

if(LIBS)
  message(FATAL_ERROR "This variable is not supported, see SOURCES instead")
endif()

target_sources(app PRIVATE
  ${ZEPHYR_BASE}/subsys/testsuite/ztest/src/ztest.c
  ${ZEPHYR_BASE}/subsys/testsuite/ztest/src/ztest_mock.c
  ${ZEPHYR_BASE}/subsys/testsuite/ztest/src/ztest_rules.c
  ${ZEPHYR_BASE}/subsys/testsuite/ztest/src/ztest_defaults.c
)

target_compile_definitions(test_interface INTERFACE ZTEST_UNITTEST)

foreach(inc ${INCLUDE})
  target_include_directories(test_interface INTERFACE ${ZEPHYR_BASE}/${inc})
endforeach()

find_program(VALGRIND_PROGRAM valgrind)
if(VALGRIND_PROGRAM)
  set(VALGRIND ${VALGRIND_PROGRAM})
  set(VALGRIND_FLAGS
    --leak-check=full
    --error-exitcode=1
    --log-file=valgrind.log
    )
endif()

add_custom_target(run
  COMMAND
  $<TARGET_FILE:app>
  DEPENDS app
  WORKING_DIRECTORY ${APPLICATION_BINARY_DIR}
  )

add_custom_target(run-test
  COMMAND
  ${VALGRIND} ${VALGRIND_FLAGS}
  $<TARGET_FILE:app>
  DEPENDS app
  WORKING_DIRECTORY ${APPLICATION_BINARY_DIR}
  )
# TODO: Redirect output to unit.log
