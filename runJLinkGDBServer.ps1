cd /D "%~dp0"

& "${Env:ProgramFiles(x86)}\SEGGER\JLink\JLinkGDBServerCL.exe" -device nrf52 -strict -timeout 0 -nogui -if swd -speed 1000 -endian little -x gdb/gdb-hooks.gdb