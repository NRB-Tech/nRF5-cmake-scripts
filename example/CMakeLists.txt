cmake_minimum_required(VERSION 3.6)

# Adjust these parameters for your hardware platform
# must be set as cache strings to ensure they are not overwritten in mesh SDK
set(IC "nRF52832" CACHE STRING "IC")
set(PLATFORM "nrf52832_xxAA"  CACHE STRING "Platform")
set(SOFTDEVICE_TYPE "s132" CACHE STRING "SoftDevice type")
set(SOFTDEVICE_VERSION "7.2.0" CACHE STRING "SoftDevice version")

# enable to output verbose info
set(CMAKE_VERBOSE_MAKEFILE off)

set(VERSION_MAJOR 1)
set(VERSION_MINOR 0)
set(VERSION_BUGFIX 0)
set(VERSION_SUFFIX "")
set(VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUGFIX}${VERSION_SUFFIX}" CACHE STRING "" FORCE)

set(CMAKE_SOURCE_DIR ${CMAKE_SOURCE_DIR} CACHE STRING "" FORCE)

# Modify this to set the correct path relative to this file.
set(nRF5_cmake_path "${CMAKE_SOURCE_DIR}/nRF5-cmake-scripts/nRF5-cmake.cmake")
if(NOT EXISTS "${nRF5_cmake_path}")
    set(nRF5_cmake_path "${CMAKE_SOURCE_DIR}/../nRF5-cmake.cmake")
endif()
include("${nRF5_cmake_path}")

# project() must be called after including nRF5-cmake.cmake but before calling nRF5_setup
# to ensure variables are set correctly
project(BlinkyExampleProject
        VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUGFIX}
        LANGUAGES NONE)

message(STATUS "Configuring CMake for nRF5 SDK for ${PROJECT_NAME} ${VERSION_STRING}")
nRF5_setup()

# uncomment to enable C++
# enable_language(CXX)

if(NOT TARGET download)
    add_subdirectory("src")
endif()