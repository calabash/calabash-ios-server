#!/usr/bin/env bash

source bin/log.sh

function ditto_or_exit {
  xcrun ditto "${1}" "${2}"
  if [ "$?" != 0 ]; then
    error "Could not copy:"
    error "  source: ${1}"
    error "  target: ${2}"
    if [ ! -e "${1}" ]; then
      error "The source file does not exist"
      error "Did a previous xcodebuild step fail?"
    fi
    error "Exiting 1"
    exit 1
  fi
}

function install_with_ditto {
  ditto_or_exit "${1}" "${2}"
  info "Installed ${2}"
}

function zip_with_ditto {
  xcrun ditto \
  -ck --rsrc --sequesterRsrc --keepParent \
  "${1}" \
  "${2}"
  info "Installed ${2}"
}

function unzip_with_ditto {
  xcrun ditto \
  -xk --rsrc --sequesterRsrc \
  "${1}" \
  "${2}"
  info "Installed ${2}"
}
