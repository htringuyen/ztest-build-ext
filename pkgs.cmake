include_guard(GLOBAL)

# zephyr_interface target for use generally in source modules
add_library(zephyr_interface INTERFACE)
target_link_libraries(zephyr_interface INTERFACE test_interface)

# syscalls_interface target for use generally in source modules
add_library(syscalls_interface INTERFACE)
target_link_libraries(syscalls_interface INTERFACE test_interface)

# zephyr target for collecting sources in lib, subsys
add_library(zephyr STATIC)
target_link_libraries(zephyr PRIVATE test_interface)

# load extra modules
foreach(module IN LISTS ZTEST_INCLUDE_EXTRA_ZEPHYR_MODULES)
    string(TOUPPER "${module}" MODULE_UPPER)
    string(REGEX REPLACE "[^A-Z]" "_" MODULE_UPPER "${MODULE_UPPER}")

    set(MODULE_DIR "${ZEPHYR_${MODULE_UPPER}_MODULE_DIR}")
    if(NOT MODULE_DIR)
        message(FATAL_ERROR "Module not found: ${module}")
    endif()
    message(STATUS "Load module at: ${MODULE_DIR}")

    if (EXISTS "${MODULE_DIR}/main")
        add_subdirectory(${MODULE_DIR}/main ${CMAKE_BINARY_DIR}/modules/${module})
    else()
        add_subdirectory(${MODULE_DIR} ${CMAKE_BINARY_DIR}/modules/${module})
    endif()
    
endforeach()

# load private headers of current module if any
if(CURRENT_MODULE_PRIVATE_INCLUDE_DIR)
    zephyr_include_directories(${CURRENT_MODULE_PRIVATE_INCLUDE_DIR})
    message(STATUS "Include private header in: ${CURRENT_MODULE_PRIVATE_INCLUDE_DIR}")
else()
    message(FATAL_ERROR "Failed to include private headers in: ${CURRENT_MODULE_PRIVATE_INCLUDE_DIR}")
endif()

# load additional packages for unit test
set(PACKAGES_BUILD_DIR "${CMAKE_BINARY_DIR}/packages")
if (CONFIG_UT_PACKAGES)
    add_subdirectory_ifdef(CONFIG_UT_CRC ${ZTEST_BUILD_EXT_BASE}/packages/crc)
    add_subdirectory_ifdef(CONFIG_UT_LOGGING ${ZTEST_BUILD_EXT_BASE}/packages/logging)
    add_subdirectory_ifdef(CONFIG_UT_MALLOC ${ZTEST_BUILD_EXT_BASE}/packages/malloc)
    add_subdirectory_ifdef(CONFIG_UT_RING_BUFFER ${ZTEST_BUILD_EXT_BASE}/packages/ring_buffer)
endif()

# collect libraries into test application target
get_property(ZEPHYR_LIBS_PROPERTY GLOBAL PROPERTY ZEPHYR_LIBS)
list(APPEND ZEPHYR_LIBS_PROPERTY zephyr)

message(STATUS "ZEPHYR_LIBRARIES = ${ZEPHYR_LIBS_PROPERTY}")

foreach(zephyr_lib ${ZEPHYR_LIBS_PROPERTY})
    get_property(lib_type TARGET ${zephyr_lib} PROPERTY TYPE)
    if(${lib_type} STREQUAL STATIC_LIBRARY 
        AND NOT ${zephyr_lib} STREQUAL app)
        get_target_property(source_list ${zephyr_lib} SOURCES)
        if(NOT source_list)
            target_sources(${zephyr_lib} PRIVATE ${ZEPHYR_BASE}/misc/empty_file.c)
        endif()
    endif()
    target_link_libraries(app PRIVATE ${zephyr_lib})
endforeach()