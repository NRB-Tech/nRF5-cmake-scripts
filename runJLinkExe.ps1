param (
    [string]$JLinkPath,
    [string]$JLinkGDBServerPath,
    [string]$JLinkRTTClientPath
)

& "${JLinkPath}" -device nrf52 -if swd -speed 4000 -autoconnect 1 -RTTTelnetPort 19022