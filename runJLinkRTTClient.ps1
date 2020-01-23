param (
    [string]$JLinkPath,
    [string]$JLinkGDBServerPath,
    [string]$JLinkRTTClientPath
)

& "$JLinkRTTClientPath" -RTTTelnetPort 19022