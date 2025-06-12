cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr COMPONENTS ztest_build_ext HINTS $ENV{ZEPHYR_BASE})

target_sources(testbinary PRIVATE src/main.c)
