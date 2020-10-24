cmake_minimum_required(VERSION 3.7.0)

set(cortex-m0_uECC "nf")
set(cortex-m4_uECC "nf")
set(cortex-m4f_uECC "hf")

if(NOT DEFINED ${ARCH}_uECC)
    message(FATAL_ERROR  "The uECC type is not found for the arch ${ARCH}, check uECC.cmake for missing arch defs")
endif()

set(uECC_ROOT "${SDK_ROOT}/external/micro-ecc")

# Download and unpack uECC at configure time
configure_file("${CMAKE_CURRENT_LIST_DIR}/uECC-dl.txt.in" ${CMAKE_BINARY_DIR}/uECC-download/CMakeLists.txt)
execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
        RESULT_VARIABLE result
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/uECC-download )
if(result)
    message(FATAL_ERROR "CMake step for uECC failed: ${result}")
endif()
execute_process(COMMAND ${CMAKE_COMMAND} --build .
        RESULT_VARIABLE result
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/uECC-download )
if(result)
    message(FATAL_ERROR "Build step for uECC failed: ${result}")
endif()

string(SUBSTRING ${PLATFORM} 0 5 uECC_PREFIX)

include(${CMAKE_CURRENT_LIST_DIR}/makefile_vars.cmake)

set(uECC_PATH "${uECC_ROOT}/${uECC_PREFIX}${${ARCH}_uECC}_armgcc/armgcc")
set(uECC_OP_FILE "${uECC_PATH}/micro_ecc_lib_${uECC_PREFIX}.a")
include(ExternalProject)
ExternalProject_Add(uECC
    SOURCE_DIR        "${uECC_ROOT}/micro-ecc"
    BINARY_DIR        "${CMAKE_BINARY_DIR}/uecc-build"
    BUILD_COMMAND     $(MAKE) -C "${uECC_PATH}" ${MAKEFILE_VARS}
    CONFIGURE_COMMAND ""
    INSTALL_COMMAND   ""
    TEST_COMMAND      ""
)
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES
        "${uECC_PATH}/_build"
        )
