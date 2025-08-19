# Resolve an 8.3 short path on Windows. Falls back to the original if unavailable.
function(get_windows_short_path IN_PATH OUT_VAR)
    # Convert to native backslashes for cmd.exe
    file(TO_NATIVE_PATH "${IN_PATH}" _native)

    # Ask cmd.exe to echo the short name. Note: single % works with `cmd /c`.
    execute_process(
            COMMAND cmd /c for %A in ("${_native}") do @echo %~sA
            OUTPUT_VARIABLE _short
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(_short STREQUAL "" OR _short MATCHES "^\"\"$")
        # Short names can be disabled on the volume; just return the original.
        set(_short "${_native}")
    endif()

    set(${OUT_VAR} "${_short}" PARENT_SCOPE)
endfunction()