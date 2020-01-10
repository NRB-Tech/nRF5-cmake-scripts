cmake_minimum_required(VERSION 3.6)

# output verbose info
set(CMAKE_VERBOSE_MAKEFILE off)

if (NOT CMAKE_VERSION VERSION_LESS 3.9)
    # Allow user to enable CMAKE_INTERPROCEDURAL_OPTIMIZATION (LTO) if supported for the toolchain.
    # This is supported from CMake version 9 and later.
    cmake_policy(SET CMP0069 NEW)
endif ()

set(VERSION_MAJOR 1)
set(VERSION_MINOR 0)
set(VERSION_BUGFIX 0)
set(VERSION_SUFFIX "")
set(VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUGFIX}${VERSION_SUFFIX}" CACHE STRING "" FORCE)

set(IC nRF52832)
# must be set as cache strings to ensure they are not overwritten in mesh SDK
set(SOFTDEVICE_TYPE "s132" CACHE STRING "SoftDevice type")
set(SOFTDEVICE_VERSION "7.0.1" CACHE STRING "SoftDevice version")

# Paths to modify
set(CMAKE_CONFIG_DIR "${CMAKE_SOURCE_DIR}/toolchains/nRF5/nrf5SDKforMeshv400src/CMake")
set(SDK_ROOT "${CMAKE_SOURCE_DIR}/toolchains/nRF5/nRF5_SDK_16.0.0_98a08e2")
find_program(NRFJPROG nrfjprog)
find_program(MERGEHEX mergehex)
find_program(NRFUTIL nrfutil)

option(BUILD_HOST "Build for host (unit test build)" OFF)

if (NOT BUILD_HOST)
    set(CMAKE_SYSTEM_NAME "Generic")
    set(CMAKE_SYSTEM_PROCESSOR "ARM")
endif (NOT BUILD_HOST)

# We enable the project() here for CMake to initialize variables s.a. "CMAKE_HOST_W32".
# Languages are enabled _after_ the toolchain has been setup.
project(BlinkyExampleProject
    VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUGFIX}
    LANGUAGES NONE)

message(STATUS "Configuring CMake for nRF5 SDK for ${PROJECT_NAME} ${VERSION_STRING}")

set(CMAKE_SOURCE_DIR ${CMAKE_SOURCE_DIR} CACHE STRING "" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/../nRF5-cmake.cmake")

if(TARGET download)
    return()
endif()

nRF5_setup()

add_subdirectory("src")
