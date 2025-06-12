include_guard(GLOBAL)

function(include_extra_zephyr_module module_name)
    list(APPEND INCLUDE_EXTRA_ZEPHYR_MODULES ${module_name})
endfunction(module_name)
