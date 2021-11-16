cmake_minimum_required(VERSION 3.5.0)

include(${CMAKE_CURRENT_LIST_DIR}/uECC.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/makefile_vars.cmake)

# taken from running nrfutil settings generate --help, see --family flag

set(nRF51xxx_FAMILY NRF51)
set(nRF52832_FAMILY NRF52)
set(nRF52832-QFAB_FAMILY NRF52QFAB)
set(nRF52810_FAMILY NRF52810)
set(nRF52840_FAMILY NRF52840)

# taken from running nrfutil pkg generate --help, see --sd-req flag,
# or in SDK/components/softdevice/sXXX/sXXX_nrfXX_X.X.X_release-notes.pdf,
# Softdevice properties, "The Firmware ID of this SoftDevice is 0xXXXX"

set(s112_6.0.0_FWID 0xA7)
set(s112_6.1.0_FWID 0xB0)
set(s112_6.1.1_FWID 0xB8)
set(s112_7.0.0_FWID 0xC4)
set(s112_7.0.1_FWID 0xCD)
set(s112_7.2.0_FWID 0x0103)
set(s113_7.0.0_FWID 0xC3)
set(s113_7.0.1_FWID 0xCC)
set(s113_7.2.0_FWID 0x0102)
set(s130_1.0.0_FWID 0x67)
set(s130_2.0.0_FWID 0x80)
set(s132_2.0.0_FWID 0x81)
set(s130_2.0.1_FWID 0x87)
set(s132_2.0.1_FWID 0x88)
set(s212_2.0.1_FWID 0x8D)
set(s332_2.0.1_FWID 0x8E)
set(s132_3.0.0_FWID 0x8C)
set(s132_3.1.0_FWID 0x91)
set(s132_4.0.0_FWID 0x95)
set(s132_4.0.2_FWID 0x98)
set(s132_4.0.3_FWID 0x99)
set(s132_4.0.4_FWID 0x9E)
set(s132_4.0.5_FWID 0x9F)
set(s212_4.0.5_FWID 0x93)
set(s332_4.0.5_FWID 0x94)
set(s132_5.0.0_FWID 0x9D)
set(s212_5.0.0_FWID 0x9C)
set(s332_5.0.0_FWID 0x9B)
set(s132_5.1.0_FWID 0xA5)
set(s132_6.0.0_FWID 0xA8)
set(s132_6.1.0_FWID 0xAF)
set(s132_6.1.1_FWID 0xB7)
set(s132_7.0.0_FWID 0xC2)
set(s132_7.0.1_FWID 0xCB)
set(s132_7.2.0_FWID 0x0101)
set(s140_6.0.0_FWID 0xA9)
set(s140_6.1.0_FWID 0xAE)
set(s140_6.1.1_FWID 0xB6)
set(s140_7.0.0_FWID 0xC1)
set(s140_7.0.1_FWID 0xCA)
set(s140_7.2.0_FWID 0x0100)
set(s212_6.1.1_FWID 0xBC)
set(s332_6.1.1_FWID 0xBA)
set(s340_6.1.1_FWID 0xB9)

set(SECURE_BOOTLOADER_SRC_DIR "${SDK_ROOT}/examples/dfu/secure_bootloader/${BOARD}_${SOFTDEVICE_TYPE}_ble/armgcc")
set(OPEN_BOOTLOADER_SRC_DIR "${SDK_ROOT}/examples/dfu/open_bootloader/${BOARD}_${SOFTDEVICE_TYPE}_ble/armgcc")

if(NOT DEFINED ${IC}_FAMILY)
    message(FATAL_ERROR "The family is not found for the IC ${IC}, define a valid IC or check secure_bootloader.cmake for missing IC defs")
endif()
set(BL_OPT_FAMILY ${${IC}_FAMILY})

message("-- IC: ${IC}")

# set to hw version e.g. 52 for nrf52
string(SUBSTRING ${PLATFORM} 3 2 BL_OPT_HW_VERSION)

if(NOT DEFINED ${SOFTDEVICE}_FWID)
    message(FATAL_ERROR "The FWID is not found for the soft device ${SOFTDEVICE}, check secure_bootloader.cmake for missing softdevice defs")
endif()
set(BL_OPT_SD_ID ${${SOFTDEVICE}_FWID})

macro(nRF5_get_BL_OPT_SD_REQ PREVIOUS_SOFTDEVICES)
    unset(BL_OPT_SD_REQ)
    set(ids_list ${BL_OPT_SD_ID})
    if(PREVIOUS_SOFTDEVICES)
        foreach(sd "${PREVIOUS_SOFTDEVICES}")
            if(NOT ${${sd}_FWID})
                message(FATAL_ERROR "The FWID is not found for the previous soft device ${sd}, check secure_bootloader.cmake for missing softdevice defs")
            endif()
            list(APPEND ids_list ${${sd}_FWID})
        endforeach()
        list(REMOVE_DUPLICATES ids_list)
    endif()

    list(JOIN ids_list "," BL_OPT_SD_REQ)
endmacro()

set(BOOTLOADER_DIR_PREFIX _build_${CMAKE_BUILD_TYPE}_)
set(SECURE_BOOTLOADER_PATH_PREFIX ${SECURE_BOOTLOADER_SRC_DIR}/${BOOTLOADER_DIR_PREFIX})
set(OPEN_BOOTLOADER_PATH_PREFIX ${OPEN_BOOTLOADER_SRC_DIR}/${BOOTLOADER_DIR_PREFIX})

# add the bootloader target.
# also sets BL_OPT_FAMILY, BL_OPT_SD_ID, BL_OPT_SD_REQ for use with nrfutil params
function(nRF5_addBootloader SECURE EXECUTABLE_NAME PUBLIC_KEY_C_PATH BUILD_FLAGS)
    if(${SECURE})
        set(TYPE SECURE)
    else()
        set(TYPE OPEN)
    endif()
    set(BUILD_DIR ${BOOTLOADER_DIR_PREFIX}${EXECUTABLE_NAME})
    set(BUILD_PATH ${${TYPE}_BOOTLOADER_SRC_DIR}/${BUILD_DIR})
    string(TOLOWER ${PLATFORM} PLATFORM_LC)
    add_custom_target(${EXECUTABLE_NAME}_bl DEPENDS "${BUILD_PATH}/bootloader.hex")
    add_custom_command(OUTPUT "${BUILD_PATH}/bootloader.hex"
            COMMAND ${CMAKE_COMMAND} -E copy "${PUBLIC_KEY_C_PATH}" "${SDK_ROOT}/examples/dfu/dfu_public_key.c"
            COMMAND ${CMAKE_COMMAND} -E make_directory "${BUILD_PATH}"
            COMMAND $(MAKE) -C "${${TYPE}_BOOTLOADER_SRC_DIR}" ${MAKEFILE_VARS} ${BUILD_FLAGS} OUTPUT_DIRECTORY="${BUILD_DIR}"
            COMMAND ${CMAKE_COMMAND} -E rename "${BUILD_PATH}/${PLATFORM_LC}_${SOFTDEVICE_TYPE}.hex" "${BUILD_PATH}/bootloader.hex"
            COMMAND ${CMAKE_COMMAND} -E rename "${BUILD_PATH}/${PLATFORM_LC}_${SOFTDEVICE_TYPE}.out" "${BUILD_PATH}/bootloader.out"
            DEPENDS uECC
            )
    set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES
            "${BUILD_PATH}"
            )
endfunction()

function(nRF5_addSecureBootloader EXECUTABLE_NAME PUBLIC_KEY_C_PATH BUILD_FLAGS)
    nRF5_addBootloader(TRUE "${EXECUTABLE_NAME}" "${PUBLIC_KEY_C_PATH}" "${BUILD_FLAGS}")
endfunction()

function(nRF5_addOpenBootloader EXECUTABLE_NAME PUBLIC_KEY_C_PATH BUILD_FLAGS)
    nRF5_addBootloader(FALSE "${EXECUTABLE_NAME}" "${PUBLIC_KEY_C_PATH}" "${BUILD_FLAGS}")
endfunction()
