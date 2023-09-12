cmake_minimum_required(VERSION 3.6)

if (NOT CMAKE_VERSION VERSION_LESS 3.9)
    # Allow user to enable CMAKE_INTERPROCEDURAL_OPTIMIZATION (LTO) if supported for the toolchain.
    # This is supported from CMake version 9 and later.
    cmake_policy(SET CMP0069 NEW)
endif ()

set(nRF5_SDK_VERSION "nRF5_SDK_17.1.0_ddde560" CACHE STRING "nRF5 SDK")
set(nRF5_MESH_SDK_VERSION "500" CACHE STRING "nRF5 Mesh SDK version")

if(NOT DEFINED nRF5_MESH_SOURCE_DIR)
    set(nRF5_MESH_SOURCE_DIR "${CMAKE_SOURCE_DIR}/toolchains/nRF5/nrf5SDKforMeshv${nRF5_MESH_SDK_VERSION}src")
endif()
set(CMAKE_CONFIG_DIR "${nRF5_MESH_SOURCE_DIR}/CMake")
if(NOT DEFINED SDK_ROOT)
    set(SDK_ROOT "${CMAKE_SOURCE_DIR}/toolchains/nRF5/${nRF5_SDK_VERSION}")
endif()

macro(ensure_prog var_name bin_name)
    find_program(${var_name} ${bin_name} DOC "Path to the `${bin_name}` command line executable")
    if(${var_name})
        message("-- Found ${bin_name}: ${${var_name}}")
    else()
        message(FATAL_ERROR "The path to the ${bin_name} utility (${var_name}) must be set.")
    endif()
endmacro()

# find programs
ensure_prog(NRFJPROG nrfjprog)
ensure_prog(MERGEHEX mergehex)
ensure_prog(NRFUTIL nrfutil)
ensure_prog(GIT git)
if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    find_program(JLINK JLink DOC "Path to `JLink.exe` command line executable")
    find_program(JLINKGDBSERVER JLinkGDBServerCL DOC "Path to `JLinkGDBServerCL.exe` command line executable")
    find_program(JLINKRTTCLIENT JLinkRTTClient DOC "Path to `JLinkRTTClient.exe` command line executable")
    if(NOT JLINK)
        set(JLINK "$ENV{ProgramFiles\(x86\)}/SEGGER/JLink/JLink.exe")
    endif()
    if(NOT JLINKGDBSERVER)
        set(JLINKGDBSERVER "$ENV{ProgramFiles\(x86\)}/SEGGER/JLink/JLinkGDBServerCL.exe")
    endif()
    if(NOT JLINKRTTCLIENT)
        set(JLINKRTTCLIENT "$ENV{ProgramFiles\(x86\)}/SEGGER/JLink/JLinkRTTClient.exe")
    endif()
else()
    find_program(JLINK JLinkExe DOC "Path to `JLinkExe` command line executable")
    find_program(JLINKGDBSERVER JLinkGDBServer DOC "Path to `JLinkGDBServer` command line executable")
    find_program(JLINKRTTCLIENT JLinkRTTClient DOC "Path to `JLinkRTTClient` command line executable")
endif ()

if(JLINK)
    message("-- Found JLinkExe: ${JLINK}")
endif()
if(JLINKGDBSERVER)
    message("-- Found JLinkGDBServer: ${JLINKGDBSERVER}")
endif()
if(JLINKRTTCLIENT)
    message("-- Found JLinkRTTClient: ${JLINKRTTCLIENT}")
endif()


# Check if all the necessary variables have been set

if(NOT IC)
    message(FATAL_ERROR "The chip (IC) must be set, e.g. \"nrf52832\"")
endif()

if(NOT SOFTDEVICE_TYPE)
    message(FATAL_ERROR "The softdevice type (SOFTDEVICE_TYPE) must be set, e.g. \"s132\"")
endif()

if(NOT SOFTDEVICE_VERSION)
    message(FATAL_ERROR "The softdevice version (SOFTDEVICE_VERSION) must be set, e.g. \"7.2.0\"")
endif()

# must be set in file (not macro) scope (in macro would point to parent CMake directory)
set(nRF5_CMAKE_PATH ${CMAKE_CURRENT_LIST_DIR})

# prevent mesh SDK warning
set(PATCH_EXECUTABLE "patch")

set(nRF5_SDK_PATCH_COMMAND "")
if(DEFINED nRF5_SDK_PATCH_FILE)
    if (EXISTS "${nRF5_SDK_PATCH_FILE}")
        set(nRF5_SDK_PATCH_COMMAND ${GIT} -C "${SDK_ROOT}" apply --ignore-space-change --ignore-whitespace --whitespace=nowarn ${nRF5_SDK_PATCH_FILE})
    endif()
endif()

set(MESH_PATCH_COMMAND "")
set(MESH_PATCH_FILE "${nRF5_CMAKE_PATH}/sdk/nrf5SDKforMeshv${nRF5_MESH_SDK_VERSION}src.patch")
if (EXISTS "${MESH_PATCH_FILE}")
    set(MESH_PATCH_COMMAND ${GIT} -C "${nRF5_MESH_SOURCE_DIR}" apply --ignore-space-change --ignore-whitespace --whitespace=nowarn ${MESH_PATCH_FILE})
endif()

macro(add_download_target name)
    if(TARGET download)
        add_dependencies(download ${name})
    else()
        add_custom_target(download DEPENDS ${name})
    endif()
endmacro()

set(SOFTDEVICE "${SOFTDEVICE_TYPE}_${SOFTDEVICE_VERSION}" CACHE STRING "${IC} SoftDevice")

# Export compilation commands to .json file (used by clang-complete backends)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

macro(nRF5_setup)
    if(nRF5_setup_complete)
        return()
    endif()
    set(nRF5_setup_complete TRUE)

    if(NOT EXISTS ${SDK_ROOT}/license.txt)
        include(ExternalProject)

        string(REGEX REPLACE "(nRF5)([1]?_SDK_)([0-9]*).*" "\\1\\2v\\3.x.x" SDK_DIR ${nRF5_SDK_VERSION})
        set(nRF5_SDK_URL "https://developer.nordicsemi.com/nRF5_SDK/${SDK_DIR}/${nRF5_SDK_VERSION}.zip")

        ExternalProject_Add(nRF5_SDK
                PREFIX "${nRF5_SDK_VERSION}"
                TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/${nRF5_SDK_VERSION}"
                SOURCE_DIR "${SDK_ROOT}/"
                DOWNLOAD_DIR "${CMAKE_CURRENT_BINARY_DIR}/zip"
                DOWNLOAD_NAME "${nRF5_SDK_VERSION}.zip"
                URL ${nRF5_SDK_URL}
                PATCH_COMMAND ${nRF5_SDK_PATCH_COMMAND}
                # No build or configure commands
                CONFIGURE_COMMAND ""
                BUILD_COMMAND ""
                INSTALL_COMMAND ""
                LOG_DOWNLOAD ON
                EXCLUDE_FROM_ALL ON)
        add_download_target(nRF5_SDK)
    endif()

    if(NOT EXISTS ${CMAKE_CONFIG_DIR}/Toolchain.cmake)
        include(ExternalProject)
        set(nRF5_MESH_SDK_URL "https://www.nordicsemi.com/-/media/Software-and-other-downloads/SDKs/nRF5-SDK-for-Mesh/nrf5SDKforMeshv${nRF5_MESH_SDK_VERSION}src.zip")

        ExternalProject_Add(nRF5_MESH_SDK
                PREFIX "nRF5_mesh_sdk"
                TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/nRF5_mesh_sdk"
                SOURCE_DIR "${nRF5_MESH_SOURCE_DIR}"
                DOWNLOAD_DIR "${CMAKE_CURRENT_BINARY_DIR}/zip"
                DOWNLOAD_NAME "meshsdk.zip"
                URL ${nRF5_MESH_SDK_URL}
                PATCH_COMMAND ${MESH_PATCH_COMMAND}
                # No build or configure commands
                CONFIGURE_COMMAND ""
                BUILD_COMMAND ""
                INSTALL_COMMAND ""
                LOG_DOWNLOAD ON
                EXCLUDE_FROM_ALL ON)
        add_download_target(nRF5_MESH_SDK)
    endif()

    if(TARGET download)
        message(WARNING "Run the 'download' target to download dependencies")
        return()
    endif()

    if(NOT CMAKE_TOOLCHAIN_FILE MATCHES "nRF5-cmake-toolchain.cmake$")
        message(WARNING "You are not specifying nRF5-cmake-toolchain.cmake as your toolchain using either --toolchain flag or -DCMAKE_TOOLCHAIN_FILE. nRF5-cmake will not cross-compile correctly.")
    endif()

    # Needed tools for generating documentation and serial PyACI
    find_package(Python3 COMPONENTS Interpreter)
    # set PYTHON_EXECUTABLE for Nordic mesh SDK
    set(PYTHON_EXECUTABLE "${Python3_EXECUTABLE}")
    find_package(Doxygen)
    find_program(DOT_EXECUTABLE "dot" PATHS ENV PATH)
    find_program(MSCGEN_EXECUTABLE "mscgen" PATHS ENV PATH)

    if (NOT BUILD_HOST)
        include("${CMAKE_CONFIG_DIR}/Nrfjprog.cmake")
    endif ()

    include("${CMAKE_CONFIG_DIR}/Toolchain.cmake")
    include("${CMAKE_CONFIG_DIR}/Platform.cmake")
    include("${CMAKE_CONFIG_DIR}/SoftDevice.cmake")
    include("${CMAKE_CONFIG_DIR}/FindDependency.cmake")
    include("${CMAKE_CONFIG_DIR}/FindSDK.cmake")

    include("${CMAKE_CONFIG_DIR}/BuildType.cmake")
    include("${CMAKE_CONFIG_DIR}/Board.cmake")
    include("${CMAKE_CONFIG_DIR}/PCLint.cmake")
    include("${CMAKE_CONFIG_DIR}/GenerateSESProject.cmake")

    include("${CMAKE_CONFIG_DIR}/sdk/${nRF5_SDK_VERSION}.cmake")
    include("${CMAKE_CONFIG_DIR}/platform/${PLATFORM}.cmake")
    include("${CMAKE_CONFIG_DIR}/softdevice/${SOFTDEVICE}.cmake")
    include("${CMAKE_CONFIG_DIR}/board/${BOARD}.cmake")

    include(${nRF5_CMAKE_PATH}/includes/libraries.cmake)

    string(SUBSTRING ${PLATFORM} 0 5 NRF_FAMILY)

    message(STATUS "SDK: ${nRF5_SDK_VERSION}")
    message(STATUS "Platform: ${PLATFORM}")
    message(STATUS "Arch: ${${PLATFORM}_ARCH}")
    message(STATUS "SoftDevice: ${SOFTDEVICE}")
    message(STATUS "Board: ${BOARD}")

    set(ARCH ${${PLATFORM}_ARCH})

    enable_language(C ASM)

    if (NOT BUILD_HOST)
        set(CMAKE_EXECUTABLE_SUFFIX ".elf")
        set(BUILD_SHARED_LIBS OFF)
        set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
    else ()
        message(STATUS "Building for HOST")
        include("${CMAKE_CONFIG_DIR}/UnitTest.cmake")
        include("${CMAKE_CONFIG_DIR}/Coverage.cmake")
        include("${CMAKE_CONFIG_DIR}/UBSAN.cmake")
    endif ()

    add_compile_options(${${ARCH}_DEFINES})

    add_link_options(-u _printf_float)

    include(${nRF5_CMAKE_PATH}/includes/secure_bootloader.cmake)

    # adds target for erasing and flashing the board with a softdevice
    add_custom_target(FLASH_SOFTDEVICE ALL
            COMMAND ${NRFJPROG} --program ${${SOFTDEVICE}_HEX_FILE} -f nrf52 --sectorerase
            COMMAND sleep 0.5s
            COMMAND ${NRFJPROG} --reset -f nrf52
            COMMENT "flashing SoftDevice"
            VERBATIM
            )

    add_custom_target(FLASH_ERASE ALL
            COMMAND ${NRFJPROG} --eraseall -f nrf52
            COMMENT "erasing flashing"
            VERBATIM
            )

    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
        set(TERMINAL "open")
        set(COMMAND_SUFFIX "")
    elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        find_program(CMD cmd)
        set(TERMINAL ${CMD} /c start powershell -noexit -ExecutionPolicy Bypass -File)
        set(POST_OPTIONS -JLinkPath ${JLINK} -JLinkGDBServerPath ${JLINKGDBSERVER} -JLinkRTTClientPath ${JLINKRTTCLIENT})
        set(COMMAND_SUFFIX ".ps1")
    else()
        set(TERMINAL "gnome-terminal" --)
        set(COMMAND_SUFFIX "")
    endif()

    if(EXISTS "${JLINK}")
        if(EXISTS "${JLINKGDBSERVER}" AND EXISTS "${JLINKRTTCLIENT}")
            add_custom_target(START_JLINK_ALL ALL
                    COMMAND ${TERMINAL} "${nRF5_CMAKE_PATH}/runJLinkGDBServer${COMMAND_SUFFIX}" ${POST_OPTIONS}
                    COMMAND ${TERMINAL} "${nRF5_CMAKE_PATH}/runJLinkExe${COMMAND_SUFFIX}" ${POST_OPTIONS}
                    COMMAND cmake -E sleep 2
                    COMMAND ${TERMINAL} "${nRF5_CMAKE_PATH}/runJLinkRTTClient${COMMAND_SUFFIX}" ${POST_OPTIONS}
                    COMMENT "started JLink commands"
                    VERBATIM
                    )
        endif()
        if(EXISTS "${JLINKRTTCLIENT}")
            add_custom_target(START_JLINK_RTT ALL
                    COMMAND ${TERMINAL} "${nRF5_CMAKE_PATH}/runJLinkExe${COMMAND_SUFFIX}" ${POST_OPTIONS}
                    COMMAND cmake -E sleep 2
                    COMMAND ${TERMINAL} "${nRF5_CMAKE_PATH}/runJLinkRTTClient${COMMAND_SUFFIX}" ${POST_OPTIONS}
                    COMMENT "started JLink RTT terminal"
                    VERBATIM
                    )
        else()
            message(WARNING "The path to the JLinkRTTClient utility (JLINKRTTCLIENT) is not set or does not exist, so START_JLINK_RTT and START_JLINK_ALL targets will not be available")
        endif()
        if(EXISTS "${JLINKGDBSERVER}")
            add_custom_target(START_JLINK_GDBSERVER ALL
                    COMMAND ${TERMINAL} "${nRF5_CMAKE_PATH}/runJLinkExe${COMMAND_SUFFIX}" ${POST_OPTIONS}
                    COMMAND cmake -E sleep 2
                    COMMAND ${TERMINAL} "${nRF5_CMAKE_PATH}/runJLinkGDBServer${COMMAND_SUFFIX}" ${POST_OPTIONS}
                    COMMENT "started JLink GDB server"
                    VERBATIM
                    )
        else()
            message(WARNING "The path to the JLinkGDBServer utility (JLINKGDBSERVER) is not set or does not exist, so START_JLINK_GDBSERVER and START_JLINK_ALL targets will not be available")
        endif()
    else()
        message(WARNING "The path to the JLink utility (JLINK) is not set or does not exist, so START_JLINK_* targets will not be available")
    endif()
endmacro()

function(nRF5_addFlashTarget isApp targetName hexFile)
    if(${isApp})
        set(OPT "--sectorerase")
    else()
        set(OPT "--recover")
    endif()
    add_custom_target(${targetName}_flash
            COMMAND ${Python3_EXECUTABLE} ${CMAKE_CONFIG_DIR}/nrfjprog.py "${hexFile}" ${OPT}
            USES_TERMINAL
            DEPENDS ${targetName})
endfunction()

function(nRF5_addAppFlashTarget targetName hexFile)
    nRF5_addFlashTarget(TRUE "${targetName}" "${hexFile}")
endfunction()

function(nRF5_addFullFlashTarget targetName hexFile)
    nRF5_addFlashTarget(FALSE "${targetName}" "${hexFile}")
endfunction()

# adds a target for comiling and flashing an executable
macro(nRF5_addExecutable EXECUTABLE_NAME SOURCE_FILES INCLUDE_DIRECTORIES LINKER_FILE SYMBOLS_TO_REMOVE_FROM_HEX)
    set(_SOURCE_FILES ${SOURCE_FILES})
    set(_INCLUDE_DIRECTORIES ${INCLUDE_DIRECTORIES})
    set(_DEFINES ${DEFINES})
    list(APPEND _SOURCE_FILES
        "${${PLATFORM}_SOURCE_FILES}"
        "${${nRF5_SDK_VERSION}_SOURCE_FILES}"
    )
    list(APPEND _INCLUDE_DIRECTORIES
        "${${SOFTDEVICE}_INCLUDE_DIRS}"
        "${${PLATFORM}_INCLUDE_DIRS}"
        "${${BOARD}_INCLUDE_DIRS}"
        "${${nRF5_SDK_VERSION}_INCLUDE_DIRS}"
    )
    list(APPEND _DEFINES
            ${USER_DEFINITIONS}
            ${${PLATFORM}_DEFINES}
            ${${BOARD}_DEFINES}
            )

    list(REMOVE_DUPLICATES _SOURCE_FILES)
    list(REMOVE_DUPLICATES _INCLUDE_DIRECTORIES)

    add_executable(${EXECUTABLE_NAME} ${_SOURCE_FILES})

    target_include_directories(${EXECUTABLE_NAME} PUBLIC ${_INCLUDE_DIRECTORIES})

    set_target_link_options(${EXECUTABLE_NAME} "${LINKER_FILE}")

    target_compile_definitions(${EXECUTABLE_NAME} PUBLIC ${_DEFINES})

    create_hex(${EXECUTABLE_NAME} "${SYMBOLS_TO_REMOVE_FROM_HEX}")

    add_ses_project(${EXECUTABLE_NAME})
endmacro()

function(nRF5_addSoftDeviceAppMergeTarget EXECUTABLE_NAME)
    if(NOT TARGET ${EXECUTABLE_NAME})
        message(FATAL_ERROR "You must call nRF5_addExecutable")
    endif()
    set(OP_FILE "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_sd_app.hex")
    add_custom_target(${EXECUTABLE_NAME}_sd_app_merge DEPENDS "${OP_FILE}")
    add_custom_command(OUTPUT "${OP_FILE}"
            COMMAND ${MERGEHEX} -m "${${SOFTDEVICE}_HEX_FILE}" "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}.hex" -o "${OP_FILE}"
            DEPENDS "${EXECUTABLE_NAME}"
            VERBATIM)
endfunction()

# Add a bootloader merge target.
# @param EXECUTABLE_NAME The name of the App executable
# @param VERSION_STRING The firmware version string
# @param PRIVATE_KEY A private key for firmware signing. Required if APP_VALIDATION or SD_VALIDATION is VALIDATE_ECDSA_P256_SHA256
# @param PREVIOUS_SOFTDEVICES A list of softdevice identifiers used in previous firmware versions
# @param APP_VALIDATION The method of boot validation for the application [NO_VALIDATION|VALIDATE_GENERATED_CRC|VALIDATE_GENERATED_SHA256|VALIDATE_ECDSA_P256_SHA256]
# @param SD_VALIDATION The method of boot validation for the softdevice [NO_VALIDATION|VALIDATE_GENERATED_CRC|VALIDATE_GENERATED_SHA256|VALIDATE_ECDSA_P256_SHA256]
# @param BOOTLOADER_VERSION The new bootloader version
function(nRF5_addBootloaderSoftDeviceAppMergeTarget EXECUTABLE_NAME VERSION_STRING PRIVATE_KEY PREVIOUS_SOFTDEVICES APP_VALIDATION SD_VALIDATION BOOTLOADER_VERSION)
    if(NOT TARGET ${EXECUTABLE_NAME}_bl)
        message(FATAL_ERROR "You must call nRF5_addSecureBootloader and provide the public key before calling nRF5_addBootloaderMergeTarget")
    endif()
    if(PREVIOUS_SOFTDEVICES)
        message("-- Previous softdevices: ${PREVIOUS_SOFTDEVICES}")
    endif()
    nRF5_get_BL_OPT_SD_REQ(${PREVIOUS_SOFTDEVICES})
    set(OP_FILE "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bl_sd_app.hex")
    set(BOOTLOADER_HEX "${SECURE_BOOTLOADER_PATH_PREFIX}${EXECUTABLE_NAME}/bootloader.hex")
    if(${APP_VALIDATION} STREQUAL "VALIDATE_ECDSA_P256_SHA256" OR ${SD_VALIDATION} STREQUAL "VALIDATE_ECDSA_P256_SHA256")
        if(${PRIVATE_KEY} STREQUAL "")
            message(FATAL_ERROR "PRIVATE_KEY parameter must be supplied when using VALIDATE_ECDSA_P256_SHA256 validation")
            return()
        endif()
        set(private_key_param " --key-file \"${PRIVATE_KEY}\"")
    else()
        set(private_key_param "")
    endif()
    add_custom_target(${EXECUTABLE_NAME}_bl_sd_app_merge DEPENDS "${OP_FILE}")
    add_custom_command(OUTPUT "${OP_FILE}"
            COMMAND ${NRFUTIL} settings generate --family ${BL_OPT_FAMILY} --application "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}.hex" --application-version-string "${VERSION_STRING}" --app-boot-validation ${APP_VALIDATION} --bootloader-version ${BOOTLOADER_VERSION} --bl-settings-version 2 --softdevice "${${SOFTDEVICE}_HEX_FILE}" --sd-boot-validation ${SD_VALIDATION}${private_key_param} "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader_setting.hex"
            COMMAND ${MERGEHEX} -m ${BOOTLOADER_HEX} "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader_setting.hex" "${${SOFTDEVICE}_HEX_FILE}" "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}.hex" -o "${OP_FILE}"
            DEPENDS "${EXECUTABLE_NAME}"
            DEPENDS "${BOOTLOADER_HEX}"
            VERBATIM)
endfunction()

function(nRF5_addBootloaderSoftDeviceMergeTarget EXECUTABLE_NAME VERSION_STRING PRIVATE_KEY PREVIOUS_SOFTDEVICES APP_VALIDATION SD_VALIDATION BOOTLOADER_VERSION)
    if(NOT TARGET ${EXECUTABLE_NAME}_bl)
        message(FATAL_ERROR "You must call nRF5_addSecureBootloader and provide the public key before calling nRF5_addBootloaderMergeTarget")
    endif()
    if(PREVIOUS_SOFTDEVICES)
        message("-- Previous softdevices: ${PREVIOUS_SOFTDEVICES}")
    endif()
    nRF5_get_BL_OPT_SD_REQ(${PREVIOUS_SOFTDEVICES})
    set(OP_FILE "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bl_sd.hex")
    set(BOOTLOADER_HEX "${SECURE_BOOTLOADER_PATH_PREFIX}${EXECUTABLE_NAME}/bootloader.hex")
    if(${APP_VALIDATION} STREQUAL "VALIDATE_ECDSA_P256_SHA256" OR ${SD_VALIDATION} STREQUAL "VALIDATE_ECDSA_P256_SHA256")
        if(${PRIVATE_KEY} STREQUAL "")
            message(FATAL_ERROR "PRIVATE_KEY parameter must be supplied when using VALIDATE_ECDSA_P256_SHA256 validation")
            return()
        endif()
        set(private_key_param " --key-file \"${PRIVATE_KEY}\"")
    else()
        set(private_key_param "")
    endif()
    add_custom_target(${EXECUTABLE_NAME}_bl_sd_merge DEPENDS "${OP_FILE}")
    add_custom_command(OUTPUT "${OP_FILE}"
            COMMAND ${NRFUTIL} settings generate --family ${BL_OPT_FAMILY} --bootloader-version ${BOOTLOADER_VERSION} --bl-settings-version 2 --softdevice "${${SOFTDEVICE}_HEX_FILE}" --sd-boot-validation ${SD_VALIDATION}${private_key_param} "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader_setting.hex"
            COMMAND ${MERGEHEX} -m ${BOOTLOADER_HEX} "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader_setting.hex" "${${SOFTDEVICE}_HEX_FILE}" -o "${OP_FILE}"
            DEPENDS "${BOOTLOADER_HEX}"
            VERBATIM)
endfunction()

function(nRF5_addBootloaderOnlyTarget PRIVATE_KEY PREVIOUS_SOFTDEVICES SD_VALIDATION BOOTLOADER_VERSION PUBLIC_KEY_C_PATH BUILD_FLAGS)
    nRF5_addSecureBootloader(generic ${PUBLIC_KEY_C_PATH} ${BUILD_FLAGS})
    set(OP_FILE "${CMAKE_CURRENT_BINARY_DIR}/generic_bl_sd.hex")
    set(BOOTLOADER_HEX "${SECURE_BOOTLOADER_PATH_PREFIX}generic/bootloader.hex")
    add_custom_target(generic_bl_sd DEPENDS "${OP_FILE}")
    add_custom_command(OUTPUT "${OP_FILE}"
            COMMAND ${NRFUTIL} settings generate --family ${BL_OPT_FAMILY} --bootloader-version ${BOOTLOADER_VERSION} --bl-settings-version 2 --softdevice "${${SOFTDEVICE}_HEX_FILE}" --sd-boot-validation ${SD_VALIDATION} --key-file "${PRIVATE_KEY}" "${CMAKE_CURRENT_BINARY_DIR}/generic_bootloader_setting.hex"
            COMMAND ${MERGEHEX} -m ${${SOFTDEVICE}_HEX_FILE} "${BOOTLOADER_HEX}" "${CMAKE_CURRENT_BINARY_DIR}/generic_bootloader_setting.hex" -o "${OP_FILE}"
            DEPENDS secure_bootloader_generic
            DEPENDS "${BOOTLOADER_HEX}"
            VERBATIM)
endfunction()

function(_addDFUPackageTarget INCLUDE_BL_SD EXECUTABLE_NAME VERSION_STRING PRIVATE_KEY PREVIOUS_SOFTDEVICES APP_VALIDATION SD_VALIDATION BOOTLOADER_VERSION)
    if(NOT TARGET ${EXECUTABLE_NAME}_bl)
        message(FATAL_ERROR "You must call nRF5_addSecureBootloader and provide the public key before calling _nRF5_addDFUPackageTarget")
    endif()

    nRF5_get_BL_OPT_SD_REQ(${PREVIOUS_SOFTDEVICES})
    set(PKG_OPT --sd-req ${BL_OPT_SD_REQ} --hw-version ${BL_OPT_HW_VERSION} --application "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}.hex" --application-version-string "${VERSION_STRING}" --app-boot-validation ${APP_VALIDATION} --key-file "${PRIVATE_KEY}")
    set(DEPENDS ${EXECUTABLE_NAME})
    if(${INCLUDE_BL_SD})
        list(APPEND PKG_OPT --sd-id ${BL_OPT_SD_ID} --bootloader "${SECURE_BOOTLOADER_PATH_PREFIX}${EXECUTABLE_NAME}/bootloader.hex" --bootloader-version ${BOOTLOADER_VERSION} --softdevice "${${SOFTDEVICE}_HEX_FILE}" --sd-boot-validation ${SD_VALIDATION})
        list(APPEND DEPENDS ${EXECUTABLE_NAME}_bl)
        set(TARGET_SUFFIX _bl_sd_app_pkg)
        set(FILENAME_SUFFIX _bl_sd_app)
    else()
        set(TARGET_SUFFIX _pkg)
        set(FILENAME_SUFFIX _app)
    endif()
    set(OP_FILE "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}${FILENAME_SUFFIX}.zip")
    add_custom_target(${EXECUTABLE_NAME}${TARGET_SUFFIX} DEPENDS "${OP_FILE}")
    add_custom_command(OUTPUT "${OP_FILE}"
            COMMAND ${NRFUTIL} pkg generate ${PKG_OPT} ${OP_FILE}
            DEPENDS ${DEPENDS}
            VERBATIM)
endfunction()

function(nRF5_addDFU_BL_SD_APP_PkgTarget EXECUTABLE_NAME VERSION_STRING PRIVATE_KEY PREVIOUS_SOFTDEVICES APP_VALIDATION SD_VALIDATION BOOTLOADER_VERSION)
    _addDFUPackageTarget(TRUE "${EXECUTABLE_NAME}" "${VERSION_STRING}" "${PRIVATE_KEY}" "${PREVIOUS_SOFTDEVICES}" "${APP_VALIDATION}" "${SD_VALIDATION}" "${BOOTLOADER_VERSION}")
endfunction()

function(nRF5_addDFU_APP_PkgTarget EXECUTABLE_NAME VERSION_STRING PRIVATE_KEY PREVIOUS_SOFTDEVICES APP_VALIDATION)
    _addDFUPackageTarget(FALSE "${EXECUTABLE_NAME}" "${VERSION_STRING}" "${PRIVATE_KEY}" "${PREVIOUS_SOFTDEVICES}" "${APP_VALIDATION}" "" "")
endfunction()

function(nRF5_print_size EXECUTABLE_NAME linker_file include_bootloader)
    set(target_depend ${EXECUTABLE_NAME})
    set(options "")
    if(EXISTS "${linker_file}.ld")
        set(target_depend ${EXECUTABLE_NAME}_sd_app_merge)
        list(APPEND options -s "${linker_file}.ld")
    endif()
    if(${include_bootloader})
        set(target_depend ${EXECUTABLE_NAME}_bl_sd_app_merge)
        list(APPEND options -b "${SECURE_BOOTLOADER_PATH_PREFIX}${EXECUTABLE_NAME}/bootloader.out")
    endif()
    if(IC STREQUAL "nRF52840")
        set(MAXRAM 262144)
        set(MAXFLASH 1048576)
    elseif(IC STREQUAL "nRF52832")
        set(MAXRAM 65536)
        set(MAXFLASH 524288)
    endif()
    add_custom_command(TARGET ${target_depend} POST_BUILD
            COMMAND ${nRF5_CMAKE_PATH}/includes/getSizes -r ${MAXRAM} -l ${MAXFLASH} -f ${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}${CMAKE_EXECUTABLE_SUFFIX} ${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}.map ${options}
            VERBATIM)
endfunction()
