# define some convenience variables to point to example project directories
set(NRF_PROJECT_NAME ble_app_blinky)
set(NRF_PROJECT_PATH ${SDK_ROOT}/examples/ble_peripheral/${NRF_PROJECT_NAME})
set(NRF_PROJECT_DEVICE_PATH ${NRF_PROJECT_PATH}/${BOARD}/${SOFTDEVICE_TYPE})

# you can specify the location of the linker script if desired instead of using a specific file name. Do not include .ld extension.
set(NRF5_LINKER_SCRIPT ${NRF_PROJECT_DEVICE_PATH}/armgcc/${NRF_PROJECT_NAME}_gcc_${NRF_FAMILY})

# DFU requirements
# List the softdevice versions previously used, or use FALSE if no previous softdevices used
set(PREVIOUS_SOFTDEVICES "s132_6.1.1")
# Set the location to the DFU private key
set(PRIVATE_KEY ${CMAKE_CURRENT_SOURCE_DIR}/../keys/dfu_private.key)
set(PUBLIC_KEY ${CMAKE_CURRENT_SOURCE_DIR}/../keys/dfu_public_key.c)
# Set the App validation type. [NO_VALIDATION|VALIDATE_GENERATED_CRC|VALIDATE_GENERATED_SHA256|VALIDATE_ECDSA_P256_SHA256]
set(APP_VALIDATION_TYPE NO_VALIDATION)
# Set the Soft Device validation type. [NO_VALIDATION|VALIDATE_GENERATED_CRC|VALIDATE_GENERATED_SHA256|VALIDATE_ECDSA_P256_SHA256]
set(SD_VALIDATION_TYPE NO_VALIDATION)
# The bootloader version (user defined)
set(BOOTLOADER_VERSION 1)
# The DFU version string (firmware version string)
set(DFU_VERSION_STRING "${VERSION_STRING}")

# Set the target name
set(target BlinkyExample)

# add the required libraries for this example
nRF5_addAppScheduler()
nRF5_addAppFIFO()
nRF5_addAppTimer()
nRF5_addAppUART()
nRF5_addAppButton()
nRF5_addPowerMgmt()
nRF5_addBSP(TRUE FALSE FALSE)
nRF5_addBLEGATT()
nRF5_addBLEQWR()
nRF5_addBLEService(ble_lbs)

# usually you would include files in this directory here, like so:
#list(APPEND SOURCE_FILES
#        main.c
#        )
#list(APPEND INCLUDE_DIRS
#        "${CMAKE_CURRENT_SOURCE_DIR}"
#        )

# for example projects we include the example source files
list(APPEND SOURCE_FILES
        ${NRF_PROJECT_PATH}/main.c
        )
list(APPEND INCLUDE_DIRS
        ${NRF_PROJECT_DEVICE_PATH}/config
        )

nRF5_addExecutable(${target} "${SOURCE_FILES}" "${INCLUDE_DIRS}" "${NRF5_LINKER_SCRIPT}" ".rtt")

# Here you would set a list of user variables to be defined for the bootloader makefile (which you have modified yourself)
set(bootloader_vars "")

# add the secure bootloader build target
nRF5_addSecureBootloader(${target} "${PUBLIC_KEY}" "${bootloader_vars}")
# add the bootloader merge target
nRF5_addBootloaderSoftDeviceAppMergeTarget(${target} ${DFU_VERSION_STRING} ${PRIVATE_KEY} ${PREVIOUS_SOFTDEVICES} ${APP_VALIDATION_TYPE} ${SD_VALIDATION_TYPE} ${BOOTLOADER_VERSION})
# add the bootloader merged flash target
nRF5_addFullFlashTarget(${target}_bl_sd_app_merge "${CMAKE_CURRENT_BINARY_DIR}/${target}_bl_sd_app.hex")
# Add the Bootloader + SoftDevice + App package target
nRF5_addDFU_BL_SD_APP_PkgTarget(${target} ${DFU_VERSION_STRING} ${PRIVATE_KEY} ${PREVIOUS_SOFTDEVICES} ${APP_VALIDATION_TYPE} ${SD_VALIDATION_TYPE} ${BOOTLOADER_VERSION})
# Add the App package target
nRF5_addDFU_APP_PkgTarget(${target} ${DFU_VERSION_STRING} ${PRIVATE_KEY} ${PREVIOUS_SOFTDEVICES} ${APP_VALIDATION_TYPE})

# print the size of consumed RAM and flash - does not yet work on Windows
if(NOT ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    nRF5_print_size(${target} ${NRF5_LINKER_SCRIPT} TRUE)
endif()
