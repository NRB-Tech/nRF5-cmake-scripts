cmake_minimum_required(VERSION 3.7.0)
if(DEFINED ARM_GCC_PATH)
    return()
endif()

find_program(ARM_GCC_BIN arm-none-eabi-gcc)
get_filename_component(ARM_GCC_PATH ${ARM_GCC_BIN} DIRECTORY)
execute_process(COMMAND ${ARM_GCC_BIN} --version OUTPUT_VARIABLE output)
string(REGEX MATCH "[0-9]\\.[0-9]\\.[0-9]" ARM_GCC_VERSION ${output})

set(MAKEFILE_VARS GNU_INSTALL_ROOT=${ARM_GCC_PATH}/ GNU_VERSION=${ARM_GCC_VERSION})

message("-- ARM GNU toolchain at ${ARM_GCC_PATH}, version ${ARM_GCC_VERSION}")