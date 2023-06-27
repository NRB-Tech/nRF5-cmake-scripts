# adds mutex lib
macro(nRF5_addMutex)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/mutex"
            )

endmacro()

# adds app error library
macro(nRF5_addAppError)
    nRF5_addLog()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/util"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/util/app_error.c"
            "${SDK_ROOT}/components/libraries/util/app_error_weak.c"
            )

endmacro()

macro(nrf5_addSectionIter)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/experimental_section_vars"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/experimental_section_vars/nrf_section_iter.c"
            )
endmacro()

# adds power management lib
macro(nRF5_addPowerMgmt)
    nRF5_addMutex()
    nrf5_addSectionIter()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/pwr_mgmt"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/pwr_mgmt/nrf_pwr_mgmt.c"
            )

endmacro()

# adds power lib
macro(nRF5_addPower)
    nRF5_addMutex()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_power.c"
            )

endmacro()

# adds balloc lib
macro(nRF5_addBalloc)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/balloc"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/balloc/nrf_balloc.c"
            )

endmacro()

# adds atomic library
macro(nRF5_addAtomic)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/atomic/"
            "${SDK_ROOT}/modules/nrfx/soc"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/atomic/nrf_atomic.c"
            "${SDK_ROOT}/modules/nrfx/soc/nrfx_atomic.c"
            )
endmacro()

# adds atomic fifo lib
macro(nRF5_addAtomicFIFO)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/atomic_fifo"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/atomic_fifo/nrf_atfifo.c"
            )

endmacro()

# adds atomic flags lib
macro(nRF5_addAtomicFlags)
    nRF5_addAtomic()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/atomic_flags"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/atomic_flags/nrf_atflags.c"
            )

endmacro()

# adds memobj lib
macro(nRF5_addMemobj)
    nRF5_addBalloc()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/memobj"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/memobj/nrf_memobj.c"
            )

endmacro()

macro(nRF5_addStackInfo)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/stack_info"
            )
endmacro()

macro(nRF5_addSHA256)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/sha256"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/sha256/sha256.c"
            )
endmacro()

macro(nRF5_addHWRNG)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_rng.c"
            )
endmacro()

macro(nRF5_addHWRNGLegacy)
    nRF5_addHWRNG()
    nRF5_addQueue()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/integration/nrfx/legacy"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/integration/nrfx/legacy/nrf_drv_rng.c"
            )
endmacro()

# Adds the mbedTLS cmake project and adds the include path for `sdk_config.h` to the mbedtls targets
macro(nRF5_includeMBEDTLS SDK_CONFIG_INCLUDE_DIR)
    if(NOT TARGET mbedtls)
        set(USE_STATIC_MBEDTLS_LIBRARY 1)
        set(ENABLE_TESTING OFF)
        set(ENABLE_PROGRAMS OFF)
        set(CMAKE_POLICY_DEFAULT_CMP0048 NEW)
        set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
        add_subdirectory("${SDK_ROOT}/external/mbedtls" mbedtls)
        # other targets link mbedcrypto and def needs to be public so only needs defining on this target
        target_compile_definitions(mbedcrypto PUBLIC MBEDTLS_CONFIG_FILE="${SDK_ROOT}/external/nrf_tls/mbedtls/nrf_crypto/config/nrf_crypto_mbedtls_config.h")
        foreach(target mbedtls mbedx509 mbedcrypto)
            target_include_directories(${target} PRIVATE ${SDK_CONFIG_INCLUDE_DIR})
        endforeach()
    endif()
endmacro()

# link mbedtls to your target. LIB_TYPE is "tls", "x509", or "crypto". x509 contains crypto, and tls contains x509.
macro(nRF5_addMBED target LIB_TYPE)
    target_link_libraries(${target} PUBLIC mbed${LIB_TYPE})
    target_include_directories(${target} PRIVATE "${SDK_ROOT}/external/mbedtls/include")
endmacro()

macro(nRF5_addCryptoBackend TYPE BACKEND)
    if(${TYPE} STREQUAL "rng")
        nRF5_addStackInfo()
    endif()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/crypto"
            # must include all headers
            "${SDK_ROOT}/components/libraries/crypto/backend/cc310"
            "${SDK_ROOT}/components/libraries/crypto/backend/cc310_bl"
            "${SDK_ROOT}/components/libraries/crypto/backend/cifra"
            "${SDK_ROOT}/components/libraries/crypto/backend/mbedtls"
            "${SDK_ROOT}/components/libraries/crypto/backend/micro_ecc"
            "${SDK_ROOT}/components/libraries/crypto/backend/nrf_hw"
            "${SDK_ROOT}/components/libraries/crypto/backend/nrf_sw"
            "${SDK_ROOT}/components/libraries/crypto/backend/oberon"
            "${SDK_ROOT}/components/libraries/crypto/backend/optiga"
            )

    if(${BACKEND} STREQUAL "nrf_hw_mbedtls" AND ${TYPE} STREQUAL "rng")
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/libraries/crypto/backend/nrf_hw/nrf_hw_backend_rng_mbedtls.c"
                "${SDK_ROOT}/components/libraries/crypto/backend/nrf_hw/nrf_hw_backend_init.c"
                )
    else()
        if(EXISTS "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_init.c")
            list(APPEND SOURCE_FILES "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_init.c")
        endif()
        if(${TYPE} STREQUAL "aead")
            list(APPEND SOURCE_FILES "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_aes_aead.c")
        else()
            list(APPEND SOURCE_FILES "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_${TYPE}.c")
        endif()
    endif()

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_${TYPE}.c"
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_init.c"
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_shared.c"
            )
    if(EXISTS "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_${TYPE}_shared.c")
        list(APPEND SOURCE_FILES "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_${TYPE}_shared.c")
    endif()

endmacro()

# adds dynamic memory manager
macro(nRF5_addMemManager)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/mem_manager"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/mem_manager/mem_manager.c"
            )

endmacro()

macro(nRF5_addFStorage INCLUDE_SD)
    nRF5_addAtomicFIFO()
    nRF5_addNVMC()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/fstorage"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/fstorage/nrf_fstorage.c"
            "${SDK_ROOT}/components/libraries/fstorage/nrf_fstorage_nvmc.c"
            )

    if(${INCLUDE_SD})
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/libraries/fstorage/nrf_fstorage_sd.c"
                )
    endif()
endmacro()

# adds app-level FDS (flash data storage) library. INCLUDE_SD parameter is boolean, pass true if you use softdevice.
macro(nRF5_addFDS INCLUDE_SD)
    nRF5_addAtomicFIFO()
    nRF5_addFStorage(${INCLUDE_SD})
    nRF5_addCRC16()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/fds"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/fds/fds.c"
            )
endmacro()

# adds svc library
macro(nRF5_addSVC)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/svc"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/svc/nrf_svc_handler.c"
            )
endmacro()

macro(nRF5_addCRC32)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/crc32"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/crc32/crc32.c"
            )
endmacro()

macro(nRF5_addCRC16)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/crc16"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/crc16/crc16.c"
            )
endmacro()

# adds dfu buttonless bootloader libs
macro(nRF5_addBootloaderButtonlessLibs)
    nRF5_addSVC()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/bootloader"
            "${SDK_ROOT}/components/libraries/bootloader/dfu"
            "${SDK_ROOT}/components/libraries/bootloader/ble_dfu"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/bootloader/nrf_bootloader_info.c"
            "${SDK_ROOT}/components/libraries/bootloader/dfu/nrf_dfu_svci.c"
            )
endmacro()

macro(nRF5_addBootloaderSettings)
    nRF5_addCRC32()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/bootloader/dfu"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/bootloader/dfu/nrf_dfu_settings.c"
            )
endmacro()

# adds hardfault handler library
macro(nRF5_addHardfaultHandler)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/hardfault"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/hardfault/hardfault_implementation.c"
            "${SDK_ROOT}/components/libraries/hardfault/nrf52/handler/hardfault_handler_gcc.c"
            )
endmacro()

# adds ring buffer library
macro(nRF5_addRingBuf)
    nRF5_addAtomic()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/ringbuf"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/ringbuf/nrf_ringbuf.c"
            )
endmacro()

# adds strerror library
macro(nRF5_addStrError)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/strerror"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/strerror/nrf_strerror.c"
            )
endmacro()

macro(nRF5_addSeggerRTT)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/external/segger_rtt"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/external/segger_rtt/SEGGER_RTT.c"
            )
endmacro()

# adds log library
macro(nRF5_addLog)
    nRF5_addRingBuf()
    nRF5_addMemobj()
    nRF5_addStrError()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/external/fprintf"
            "${SDK_ROOT}/components/libraries/log/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/external/fprintf/nrf_fprintf.c"
            "${SDK_ROOT}/external/fprintf/nrf_fprintf_format.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_str_formatter.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_frontend.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_default_backends.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_backend_flash.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_backend_rtt.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_backend_serial.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_backend_uart.c"
            )
endmacro()

# adds aSAADC driver
macro(nRF5_addSAADC)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_saadc.c"
            )
endmacro()

# adds PPI driver
macro(nRF5_addPPI)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_ppi.c"
            )
endmacro()

macro(nRF5_addWDT)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_wdt.c"
            )
endmacro()

# adds timer driver
macro(nRF5_addTimer)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_timer.c"
            )
endmacro()

# adds gpiote driver
macro(nRF5_addGPIOTE)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_gpiote.c"
            )
endmacro()

# adds rtc driver
macro(nRF5_addRTC)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_rtc.c"
            )
endmacro()

# adds pwm driver
macro(nRF5_addPWM)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_pwm.c"
            )
endmacro()

# adds COMP driver
macro(nRF5_addCOMP)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_comp.c"
            )
endmacro()

# adds peripheral resource sharing driver
macro(nRF5_addPRS)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/src/prs"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/prs/nrfx_prs.c"
            )
endmacro()

# adds uart driver
macro(nRF5_addUART)
    nRF5_addPRS()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_uart.c"
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_uarte.c"
            )
endmacro()

# adds legacy uart driver
macro(nRF5_addLegacyUART)
    nRF5_addUART()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/integration/nrfx/legacy"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/integration/nrfx/legacy/nrf_drv_uart.c"
            )
endmacro()

# adds serial library
macro(nRF5_addSerial)
    nRF5_addLegacyUART()
    nRF5_addMutex()
    nRF5_addQueue()
    nRF5_addAppTimer()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/serial"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/serial/nrf_serial.c"
            )
endmacro()

macro(nRF5_addLibuarteDrv)
    nRF5_addUART()
    nRF5_addGPIOTE()
    nRF5_addPRS()
    nRF5_addPPI()
    nRF5_addTimer()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/libuarte"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/libuarte/nrf_libuarte_drv.c"
            )
endmacro()

macro(nRF5_addLibuarteAsync)
    nRF5_addLibuarteDrv()
    nRF5_addBalloc()
    nRF5_addQueue()
    nRF5_addRTC()

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/libuarte/nrf_libuarte_async.c"
            )
endmacro()

# adds timer driver
macro(nRF5_addTimer)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_timer.c"
            )
endmacro()

# adds nvmc HAL
macro(nRF5_addNVMC)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/hal"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/hal/nrf_nvmc.c"
            )
endmacro()

# adds queue library
macro(nRF5_addQueue)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/queue"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/queue/nrf_queue.c"
            )
endmacro()

# adds app-level scheduler library
macro(nRF5_addAppScheduler)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/scheduler"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/scheduler/app_scheduler.c"
            )

endmacro()

# adds app-level FIFO libraries
macro(nRF5_addAppFIFO)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/fifo"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/fifo/app_fifo.c"
            )

endmacro()

macro(nRF5_addSortlist)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/sortlist"
            )
    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/sortlist/nrf_sortlist.c"
            )
endmacro()

# adds app-level Timer libraries
macro(nRF5_addAppTimer)
    list(APPEND INCLUDE_DIRS
      "${SDK_ROOT}/components/libraries/timer"
      )
    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/timer/app_timer.c"
            )
endmacro()

macro(nRF5_addAppTimerV2)
    nRF5_addRTC()
    nRF5_addSortlist()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/timer"
            )
    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/timer/app_timer2.c"
            "${SDK_ROOT}/components/libraries/timer/drv_rtc.c"
            )
endmacro()

# adds app UART library
macro(nRF5_addAppUART)
    nRF5_addLegacyUART()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/uart"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/uart/app_uart_fifo.c"
            )

endmacro()

# adds app-level Button library
macro(nRF5_addAppButton)
    nRF5_addGPIOTE()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/button"
            "${SDK_ROOT}/integration/nrfx/legacy"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/button/app_button.c"
            )

endmacro()

macro(nRF5_addESB)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/proprietary_rf/esb"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/proprietary_rf/esb/nrf_esb.c"
            )
endmacro()

# adds BSP (board support package) library
macro(nRF5_addBSP WITH_BLE_BTN WITH_ANT_BTN WITH_NFC)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/bsp"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/boards/boards.c"
            "${SDK_ROOT}/components/libraries/bsp/bsp.c"
            )

    if (${WITH_BLE_BTN})
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/libraries/bsp/bsp_btn_ble.c"
                )
    endif ()

    if (${WITH_ANT_BTN})
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/libraries/bsp/bsp_btn_ant.c"
                )
    endif ()

    if (${WITH_NFC})
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/libraries/bsp/bsp_nfc.c"
                )
    endif ()

endmacro()

macro(nRF5_addSoftDeviceSupport)
    nRF5_addMemobj()
    nRF5_addStrError()
    nRF5_addAppError()
    nRF5_addAtomicFlags()
    nrf5_addSectionIter()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/common"
            "${SDK_ROOT}/components/softdevice/common"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/util/app_util_platform.c"
            "${SDK_ROOT}/components/softdevice/common/nrf_sdh_soc.c"
            "${SDK_ROOT}/components/softdevice/common/nrf_sdh_ble.c"
            "${SDK_ROOT}/components/softdevice/common/nrf_sdh.c"
            "${SDK_ROOT}/components/ble/common/ble_conn_state.c"
            "${SDK_ROOT}/components/ble/common/ble_conn_params.c"
            "${SDK_ROOT}/components/ble/common/ble_advdata.c"
            "${SDK_ROOT}/components/ble/common/ble_srv_common.c"
            )

    list(APPEND DEFINES
            ${${SOFTDEVICE}_DEFINES}
            )
endmacro()

# adds Bluetooth Low Energy GATT support library
macro(nRF5_addBLEGATT)
    nRF5_addSoftDeviceSupport()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/nrf_ble_gatt"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/nrf_ble_gatt/nrf_ble_gatt.c"
            )
endmacro()

# adds Bluetooth Low Energy advertising support library
macro(nRF5_addBLEAdvertising)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/ble_advertising"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/ble_advertising/ble_advertising.c"
            )
endmacro()

# adds Bluetooth Low Energy scanning support library
macro(nRF5_addBLEScan)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/nrf_ble_scan"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/nrf_ble_scan/nrf_ble_scan.c"
            )
endmacro()

# adds Bluetooth Low Energy DB discovery library
macro(nRF5_addBLEDBDiscovery)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/ble_db_discovery"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/ble_db_discovery/ble_db_discovery.c"
            )
endmacro()

# adds Bluetooth Low Energy GATT queue library
macro(nRF5_addBLEGQ)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/nrf_ble_gq"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/nrf_ble_gq/nrf_ble_gq.c"
            )
endmacro()

# adds Bluetooth Low Energy Queued Write library
macro(nRF5_addBLEQWR)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/nrf_ble_qwr"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/nrf_ble_qwr/nrf_ble_qwr.c"
            )
endmacro()

macro(nRF5_addBLELinkCtxManager)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/ble_link_ctx_manager"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/ble_link_ctx_manager/ble_link_ctx_manager.c"
            )
endmacro()

# adds Bluetooth Low Energy advertising support library
macro(nRF5_addBLEPeerManager)
    nRF5_addFDS(TRUE)
    nRF5_addAtomicFlags()
    nRF5_addMutex()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/peer_manager"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/peer_manager/auth_status_tracker.c"
            "${SDK_ROOT}/components/ble/peer_manager/gatt_cache_manager.c"
            "${SDK_ROOT}/components/ble/peer_manager/gatts_cache_manager.c"
            "${SDK_ROOT}/components/ble/peer_manager/id_manager.c"
            "${SDK_ROOT}/components/ble/peer_manager/nrf_ble_lesc.c"
            "${SDK_ROOT}/components/ble/peer_manager/peer_data_storage.c"
            "${SDK_ROOT}/components/ble/peer_manager/peer_database.c"
            "${SDK_ROOT}/components/ble/peer_manager/peer_id.c"
            "${SDK_ROOT}/components/ble/peer_manager/peer_manager.c"
            "${SDK_ROOT}/components/ble/peer_manager/peer_manager_handler.c"
            "${SDK_ROOT}/components/ble/peer_manager/pm_buffer.c"
            "${SDK_ROOT}/components/ble/peer_manager/security_dispatcher.c"
            "${SDK_ROOT}/components/ble/peer_manager/security_manager.c"
            )

endmacro()

# adds NFC library
macro(nRF5_addNFC)
    # NFC includes
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser"
            "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/ac_rec_parser"
            "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/ble_oob_advdata_parser"
            "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/le_oob_rec_parser"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ac_rec"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_oob_advdata"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_pair_lib"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_pair_msg"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/common"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ep_oob_rec"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/hs_rec"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/le_oob_rec"
            "${SDK_ROOT}/components/nfc/ndef/generic/message"
            "${SDK_ROOT}/components/nfc/ndef/generic/record"
            "${SDK_ROOT}/components/nfc/ndef/launchapp"
            "${SDK_ROOT}/components/nfc/ndef/parser/message"
            "${SDK_ROOT}/components/nfc/ndef/parser/record"
            "${SDK_ROOT}/components/nfc/ndef/text"
            "${SDK_ROOT}/components/nfc/ndef/uri"
            "${SDK_ROOT}/components/nfc/platform"
            "${SDK_ROOT}/components/nfc/t2t_lib"
            "${SDK_ROOT}/components/nfc/t2t_parser"
            "${SDK_ROOT}/components/nfc/t4t_lib"
            "${SDK_ROOT}/components/nfc/t4t_parser/apdu"
            "${SDK_ROOT}/components/nfc/t4t_parser/cc_file"
            "${SDK_ROOT}/components/nfc/t4t_parser/hl_detection_procedure"
            "${SDK_ROOT}/components/nfc/t4t_parser/tlv"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/ac_rec_parser/nfc_ac_rec_parser.c"
            "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/ble_oob_advdata_parser/nfc_ble_oob_advdata_parser.c"
            "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/le_oob_rec_parser/nfc_le_oob_rec_parser.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ac_rec/nfc_ac_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_oob_advdata/nfc_ble_oob_advdata.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_pair_lib/nfc_ble_pair_lib.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_pair_msg/nfc_ble_pair_msg.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/common/nfc_common.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ep_oob_rec/nfc_ep_oob_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/hs_rec/nfc_hs_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/le_oob_rec/nfc_le_oob_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/generic/message/nfc_ndef_msg.c"
            "${SDK_ROOT}/components/nfc/ndef/generic/record/nfc_ndef_record.c"
            "${SDK_ROOT}/components/nfc/ndef/launchapp/nfc_launchapp_msg.c"
            "${SDK_ROOT}/components/nfc/ndef/launchapp/nfc_launchapp_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/parser/message/nfc_ndef_msg_parser.c"
            "${SDK_ROOT}/components/nfc/ndef/parser/message/nfc_ndef_msg_parser_local.c"
            "${SDK_ROOT}/components/nfc/ndef/parser/record/nfc_ndef_record_parser.c"
            "${SDK_ROOT}/components/nfc/ndef/text/nfc_text_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/uri/nfc_uri_msg.c"
            "${SDK_ROOT}/components/nfc/ndef/uri/nfc_uri_rec.c"
            "${SDK_ROOT}/components/nfc/platform/nfc_platform.c"
            "${SDK_ROOT}/components/nfc/t2t_parser/nfc_t2t_parser.c"
            "${SDK_ROOT}/components/nfc/t4t_parser/apdu/nfc_t4t_apdu.c"
            "${SDK_ROOT}/components/nfc/t4t_parser/cc_file/nfc_t4t_cc_file.c"
            "${SDK_ROOT}/components/nfc/t4t_parser/hl_detection_procedure/nfc_t4t_hl_detection_procedures.c"
            "${SDK_ROOT}/components/nfc/t4t_parser/tlv/nfc_t4t_tlv_block.c"
            )
endmacro()

macro(nRF5_addBLEService NAME)
    nRF5_addBLEAdvertising()
    nRF5_addBLELinkCtxManager()
    nRF5_addBLEGATT()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/ble_services/${NAME}"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/ble_services/${NAME}/${NAME}.c"
            )

    if("${NAME}" STREQUAL "ble_dfu")
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/ble/ble_services/${NAME}/${NAME}_bonded.c"
                "${SDK_ROOT}/components/ble/ble_services/${NAME}/${NAME}_unbonded.c"
                )
        nRF5_addBootloaderButtonlessLibs()
        nRF5_addBLEPeerManager()
    endif()
endmacro()

macro(nRF5_addAssert)
    list(APPEND INCLUDE_DIRS
      "${SDK_ROOT}/components/libraries/util"
      )
    list(APPEND SOURCE_FILES
      "${SDK_ROOT}/components/libraries/util/nrf_assert.c"
      )
endmacro()

macro(nRF5_addTWI)
    nRF5_addPRS()
    list(APPEND INCLUDE_DIRS
      "${SDK_ROOT}/modules/nrfx/drivers/include"
      )

    list(APPEND SOURCE_FILES
      "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_twi.c"
      )
endmacro()

macro(nRF5_addTWILegacy)
    nRF5_addTWI()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/integration/nrfx/legacy"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/integration/nrfx/legacy/nrf_drv_twi.c"
            )
endmacro()

macro(nRF5_addTWIManager)
    list(APPEND INCLUDE_DIRS
      "${SDK_ROOT}/components/libraries/twi_mngr"
      )

    list(APPEND SOURCE_FILES
      "${SDK_ROOT}/components/libraries/twi_mngr/nrf_twi_mngr.c"
      )
endmacro()

macro(nRF5_addClock)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/integration/nrfx/legacy/nrf_drv_clock.c"
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_clock.c"
            )
endmacro()

