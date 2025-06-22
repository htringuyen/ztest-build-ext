####################################################################################
# Custom cmake functions and macros
# Need to be loaded before running top-level cmake
####################################################################################

#include_guard(GLOBAL)

message(STAUTS "*** CMAKE_USER_MAKE_RULES_OVERRIDE loaded successfully! ***")

function(find_current_module)
    set(SEARCH_LEVELS 8)
    get_filename_component(CURRENT_DIR ${CMAKE_SOURCE_DIR} ABSOLUTE)
    
    set(SEARCH_DIR ${CURRENT_DIR})
    
    foreach(LEVEL RANGE ${SEARCH_LEVELS})
        if(EXISTS "${SEARCH_DIR}/zephyr" AND IS_DIRECTORY "${SEARCH_DIR}/zephyr")
            if(EXISTS "${SEARCH_DIR}/zephyr/module.yml" OR EXISTS "${SEARCH_DIR}/zephyr/module.yaml")
                set(module_dir ${SEARCH_DIR} PARENT_SCOPE)
                get_filename_component(module_name ${SEARCH_DIR} NAME)
                set(module_name ${module_name} PARENT_SCOPE)
                return()
            endif()
        endif()
        
        get_filename_component(PARENT_DIR ${SEARCH_DIR} DIRECTORY)
        if("${PARENT_DIR}" STREQUAL "${SEARCH_DIR}")
            break()
        endif()
        set(SEARCH_DIR ${PARENT_DIR})
    endforeach()
    
    message(FATAL_ERROR "No zephyr module directory found within ${SEARCH_LEVELS} parent directories")
endfunction()

function(parse_module_id input_string out_module_name out_module_dir)
  # Count colons to ensure exactly one
  string(REGEX MATCHALL ":" colon_matches "${input_string}")
  list(LENGTH colon_matches colon_count)

  if(NOT colon_count EQUAL 1)
    message(FATAL_ERROR "Input '${input_string}' must be in the format module_name:module_dir")
  endif()

  # Find the position of the colon
  string(FIND "${input_string}" ":" sep_pos)

  # Extract module_name and module_dir
  string(SUBSTRING "${input_string}" 0 ${sep_pos} module_name)
  math(EXPR dir_start "${sep_pos} + 1")
  string(SUBSTRING "${input_string}" ${dir_start} -1 module_dir)

  # Return the values through out parameters
  set(${out_module_name} "${module_name}" PARENT_SCOPE)
  set(${out_module_dir}  "${module_dir}"  PARENT_SCOPE)
endfunction()

function(include_current_module_private_apis module_dir)
  #zephyr_include_directories(${module_dir}/main/clang)
  set(CURRENT_MODULE_PRIVATE_INCLUDE_DIR ${module_dir}/main/clang CACHE INTERNAL "")
  message("Set private api include dir: ${CURRENT_MODULE_PRIVATE_INCLUDE_DIR}")
endfunction()

function(select_testing_package_if_any module_name module_dir)
  set(clang_dir ${module_dir}/test/clang)
  get_filename_component(normalized_source_dir "${CMAKE_SOURCE_DIR}" ABSOLUTE)
  get_filename_component(normalized_clang_dir "${clang_dir}" ABSOLUTE)
  string(FIND "${normalized_source_dir}" "${normalized_clang_dir}" found_pos)
  
  if(found_pos EQUAL 0)
    # this must be a testing application, enable testing mode
    set(CONFIG_TWISTER_TESTING y CACHE STRING "Enable testing mode")

    message(STATUS "Detected testing package...")
    file(RELATIVE_PATH relative_path "${normalized_clang_dir}" "${normalized_source_dir}")
    if(relative_path STREQUAL "")
        set(relative_path ".")
    endif()
    message(STATUS "  Clang dir: ${normalized_clang_dir}")
    message(STATUS "  Source dir: ${normalized_source_dir}")
    message(STATUS "  Relative path: ${relative_path}")

    string(REPLACE "/" "_" package_normalized_name "${relative_path}")
    string(REPLACE "-" "_" module_normalized_name "${module_name}")
    string(TOUPPER "CONFIG_${module_normalized_name}_${package_normalized_name}" package_config_str)
    set(${package_config_str} y CACHE STRING "Enable testing package")
    message("Testing package selected: ${package_config_str}=y")
  endif()
endfunction()

function(zephyr_include_module module_id)

  if(${module_id} STREQUAL ":self")
    find_current_module()
    include_current_module_private_apis(${module_dir})
    select_testing_package_if_any(${module_name} ${module_dir})
  else()
    parse_module_id("${module_id}" module_name module_dir)
  endif()

  if(DEFINED EXTRA_ZEPHYR_MODULES)
    set(EXTRA_ZEPHYR_MODULES "${EXTRA_ZEPHYR_MODULES};${module_dir}" PARENT_SCOPE)
  else()
    set(EXTRA_ZEPHYR_MODULES "${module_dir}" PARENT_SCOPE)
  endif()

  if(DEFINED ZTEST_INCLUDE_EXTRA_ZEPHYR_MODULES)
    set(ZTEST_INCLUDE_EXTRA_ZEPHYR_MODULES "${ZTEST_INCLUDE_EXTRA_ZEPHYR_MODULES};${module_name}" PARENT_SCOPE)
  else()
    set(ZTEST_INCLUDE_EXTRA_ZEPHYR_MODULES "${module_name}" PARENT_SCOPE)
  endif()
endfunction()
