#!/usr/bin/env bash

# Centralized SDK version definitions for bash scripts.
# Source this file from helper scripts to get consistent versions.

# Parse versions from versions.cmake located alongside this script
_this_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
_versions_cmake="${_this_dir}/versions.cmake"

_parse_cmake_var() {
  local var_name="$1"
  if [[ -f "${_versions_cmake}" ]]; then
    local value
    value=$(grep -oE "set\\(${var_name} \\\"[^\\\"]+\\\"" "${_versions_cmake}" | sed -E 's/.*\"([^\"]+)\"/\1/' || true)
    if [[ -n "${value}" ]]; then
      echo "${value}"
      return 0
    fi
  fi
  echo ""
}

# Respect pre-set env vars, otherwise parse; if parsing fails, error out
if [[ -z "${NRF5_SDK_VERSION:-}" ]]; then
  parsed_sdk="$(_parse_cmake_var nRF5_SDK_VERSION_DEFAULT)"
  if [[ -z "${parsed_sdk}" ]]; then
    echo "Error: failed to parse nRF5_SDK_VERSION_DEFAULT from ${_versions_cmake}" >&2
    exit 1
  fi
  export NRF5_SDK_VERSION="${parsed_sdk}"
fi

if [[ -z "${NRF5_MESH_SDK_VERSION:-}" ]]; then
  parsed_mesh="$(_parse_cmake_var nRF5_MESH_SDK_VERSION_DEFAULT)"
  if [[ -z "${parsed_mesh}" ]]; then
    echo "Error: failed to parse nRF5_MESH_SDK_VERSION_DEFAULT from ${_versions_cmake}" >&2
    exit 1
  fi
  export NRF5_MESH_SDK_VERSION="${parsed_mesh}"
fi


