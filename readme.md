# nRF5-cmake-scripts

CMake scripts for developing projects with Nordic Semiconductor nRF5 series SoCs, utilising the CMake scripts found in the Nordic nRF5 Mesh SDK.

This project originally forked from [cmake-nRF5x](https://github.com/Polidea/cmake-nRF5x) which is a self-contained nRF5 CMake solution. As this project takes a different approach (using Nordic Mesh SDK) it was set up as a new project.

Currently supports:

* nRF5 SDK v17.1.0
* nRF5 Mesh SDK v5.0.0

## Dependencies

The script makes use of the following dependencies which are downloaded by the script:

- nRF5 SDK by Nordic Semiconductor - SoC specific drivers and libraries (also includes a lot of examples)
- nRF5 mesh SDK by Nordic Semiconductor - A mesh SDK which uses CMake, and is used for its CMake configuration

The script depends on the following external dependencies:

- [JLink](https://www.segger.com/downloads/jlink/#J-LinkSoftwareAndDocumentationPack) by Segger - interface software for the JLink familiy of programmers
- [Nordic command line tools](https://www.nordicsemi.com/Software-and-tools/Development-Tools/nRF-Command-Line-Tools/Download#infotabs) (`nrfjprog` and `mergehex`) by Nordic Semiconductor - Wrapper utility around JLink
- [Python](https://www.python.org/downloads/)
- [Nordic nrfutil](https://infocenter.nordicsemi.com/index.jsp?topic=%2Fug_nrfutil%2FUG%2Fnrfutil%2Fnrfutil_intro.html) by Nordic Semiconductor - a utility for generating DFU packages. Install with `pip install nrfutil`.
- [ARM GNU Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) by ARM and the GCC Team - compiler toolchain for embedded (= bare metal) ARM chips. On Windows, download directly. On a Mac, can be installed with homebrew:
    ```shell
    brew tap ArmMbed/homebrew-formulae
    brew install arm-none-eabi-gcc
    ```

## Setup

The script depends on the nRF5 SDK and the nRF5 mesh SDK. It can download these dependencies for you.

After setting up your CMakeLists.txt as described below, or using the example project, to download the dependencies run:

```shell
cmake -Bcmake-build-download -G "Unix Makefiles"
cmake --build cmake-build-download/ --target download
cmake -Bcmake-build-debug --toolchain nRF5-cmake-scripts/nRF5-cmake-toolchain.cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug
```

This will download the dependencies and then generate the build files using the toolchain.

### Creating your own project

_Note_: You can also follow the tutorial on the [NRB Tech blog](https://nrbtech.io/blog/2020/1/4/using-cmake-for-nordic-nrf52-projects).

1. Download this repo (or add as submodule) to the directory `nRF5-cmake-scripts` in your project

1. It is recommended that you copy the example `CMakeLists.txt` and `src/CMakeLists.txt` into your project, but you can inspect these and change the structure or copy as you need

1. Search the SDK `example` directory for a `sdk_config.h`, `main.c` and a linker script (normally named `<project_name>_gcc_<chip familly>.ld`) that fits your chip and project needs

1. Copy the `sdk_config.h` and the project `main.c` into a new directory `src`. Modify them as required for your project

1. Copy the linker script from the example's `armgcc` directory into your project

1. Adjust the example `CMakeList.txt` files for your requirements, and to point at your source files

    _Note_: By default, C and assembly languages are enabled. You can add C++ with `enable_language(C ASM)`
	
1. Optionally add additional libraries:

    Many drivers and libraries are wrapped with macros to include them in your project, see `includes/libraries.cmake`. If you need one isn't implemented, please create an issue or pull request. 

    To include BLE services, use `nRF5_addBLEService(<service name>)`.

## Build

After setup you can use cmake as usual:

1. Generate the build files:

	```shell
	cmake -Bcmake-build-debug --toolchain nRF5-cmake-scripts/nRF5-cmake-toolchain.cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug
	```

2. Build your app:

	```shell
	cmake --build cmake-build-debug --target <your target name>
	```

There are also other targets available:

- `merge_<your target name>`: Builds the application and merges the SoftDevice
- `secure_bootloader_<your target name>`: Builds the secure bootloader for this target
- `uECC`: Builds the uECC library
- `bl_merge_<your target name>`: Builds your application and the secure bootloader, merges these and the softdevice
- `pkg_<your target name>`: Builds and packages your application for DFU
- `pkg_bl_sd_<your target name>`: Builds and packages your application, the SoftDevice, and bootloader for DFU.

## Enabling C++

Immediately after the call to `nRF5_setup()` in your root `CMakeLists.txt`, add the line:

```
enable_language(CXX)
```

## SEGGER RTT logging in bootloader and app

By default, SEGGER RTT will be init in the bootloader, and then re-init in the app at a different memory location. The RTT client reads memory directly from RAM, so will only pick up on the App's RTT memory. To make RTT work across bootloader and app you need to only init in the bootloader and ensure the App continues to use the same RAM location for RTT.

To do this, create a new header `rtt_config.h`, add:

```c
#define SEGGER_RTT_SECTION ".rtt"
``` 

and also copy in all the `SEGGER_RTT_CONFIG_...` defines from `sdk_config.h`/`app_config.h`. Include this file in your `sdk_config.h`/`app_config.h` and the bootloader `sdk_config.h`/`app_config.h`.

In the nRF52 SDK, `modules/nrfx/mdk/nrf_common.ld`, add the following before `.data : AT (__etext)`:

```
.rtt:
{
} > RAM
```

This symbol must be removed from the hex file, to do this ensure ".rtt" is in the list of symbols to remove from hex passed to `nRF5_addExecutable` (see example project).

Ensure the RAM start and size are aligned in the app and bootloader linker scripts.

In the nRF52 SDK, `external/segger_rtt/SEGGER_RTT.c`, change the `SEGGER_RTT_Init` function to:

```c
void SEGGER_RTT_Init (void) {
    INIT();
}
```

This ensures that RTT is not re-init in the App if already init in the bootloader.

Ensure all the SEGGER files are compiled in your bootloader – refer to the `_debug` makefiles to see what is required.

Ensure the bootloader `sdk_config.h`/`app_config.h` is configured to use RTT.

You should then see continuous RTT output from the bootloader and App.

## Flash

In addition to the build targets the script adds some support targets:

- `FLASH_SOFTDEVICE`: Flashes the nRF softdevice to the SoC (typically done only once for each SoC if not using DFU flash target)
- `flash_<your target name>`: Builds and flashes your application
- `flash_bl_merge_<your target name>`: Builds the bootloader and application, and flashes both and the softdevice
- `FLASH_ERASE`: Erases the SoC flash

# JLink Applications

To start the gdb server and RTT terminal, build the target `START_JLINK_ALL`:

```shell
cmake --build "cmake-build" --target START_JLINK_ALL
```

There are also the targets `START_JLINK_RTT` and `START_JLINK_GDBSERVER` to start these independently.

# License

MIT. 

Please note that the nRF5 SDK and mesh SDK by Nordic Semiconductor are covered by their own licenses and shouldn't be re-distributed. 
