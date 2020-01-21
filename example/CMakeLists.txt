cmake_minimum_required(VERSION 3.6)

# output verbose info
set(CMAKE_VERBOSE_MAKEFILE off)

set(VERSION_MAJOR 1)
set(VERSION_MINOR 0)
set(VERSION_BUGFIX 0)
set(VERSION_SUFFIX "")
set(VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUGFIX}${VERSION_SUFFIX}" CACHE STRING "" FORCE)

set(IC nRF52832)
# must be set as cache strings to ensure they are not overwritten in mesh SDK
set(SOFTDEVICE_TYPE "s132" CACHE STRING "SoftDevice type")
set(SOFTDEVICE_VERSION "7.0.1" CACHE STRING "SoftDevice version")

set(CMAKE_SOURCE_DIR ${CMAKE_SOURCE_DIR} CACHE STRING "" FORCE)

# Windows users modify as required
if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    set(PATCH_EXECUTABLE "$ENV{ProgramFiles\(x86\)}/GnuWin32/bin/patch.exe")
endif()

# must be set before project, otherwise causes linking issues
set(CMAKE_SYSTEM_NAME "Generic")
set(CMAKE_SYSTEM_PROCESSOR "ARM")

# We enable the project() here for CMake to initialize variables s.a. "CMAKE_HOST_W32".
# Languages are enabled _after_ the toolchain has been setup.
project(BlinkyExampleProject
        VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUGFIX}
        LANGUAGES NONE)

# Modify this to set the correct path relative to this file.
set(nRF5_cmake_path "${CMAKE_SOURCE_DIR}/nRF5-cmake-scripts/nRF5-cmake.cmake")
if(NOT EXISTS nRF5_cmake_path)
    set(nRF5_cmake_path "${CMAKE_SOURCE_DIR}/../nRF5-cmake.cmake")
endif()
include("${nRF5_cmake_path}")

if(TARGET download)
    return()
endif()

message(STATUS "Configuring CMake for nRF5 SDK for ${PROJECT_NAME} ${VERSION_STRING}")
nRF5_setup()
add_subdirectory("src")