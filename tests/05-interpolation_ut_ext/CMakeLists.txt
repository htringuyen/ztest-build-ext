# Copyright (c) 2024 Embeint Inc
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr COMPONENTS ztest_build_ext REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(interpolation)

target_link_libraries(app PRIVATE m)
target_sources(app PRIVATE src/main.c)
