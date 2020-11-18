# Changelog

## 17 November 2020

* Renamed `nRF5_addBootloaderMergeTarget` to `nRF5_addBootloaderSoftDeviceAppMergeTarget`
* `nRF5_addExecutable` no longer adds flash targets – use `nRF5_addSoftDeviceAppMergeTarget` and `nRF5_addAppFlashTarget`/`nRF5_addFullFlashTarget` as required
* Added `nRF5_addBootloaderSoftDeviceMergeTarget`
* Renamed targets and output files to be more consistent
* Removed nRF Mesh `merge` target and functions which weren't needed 