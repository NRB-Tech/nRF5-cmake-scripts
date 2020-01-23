param (
    [string]$JLinkPath,
    [string]$JLinkGDBServerPath,
    [string]$JLinkRTTClientPath
)

cd /D "%~dp0"

& "$JLinkGDBServerPath" -device nrf52 -strict -timeout 0 -nogui -if swd -speed 1000 -endian little -x gdb/gdb-hooks.gdb