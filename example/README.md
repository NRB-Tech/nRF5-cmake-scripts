# Example

This is an example to build the blinky project. To test, run:

```shell
cmake -Bcmake-build-download -G "Unix Makefiles"
cmake --build cmake-build-download/ --target download
cmake -Bcmake-build-debug -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug
cmake --build cmake-build-debug/ --target flash_BlinkyExample 
```
