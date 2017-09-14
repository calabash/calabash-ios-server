#!/usr/bin/env bash

source bin/log.sh
source bin/ditto.sh

FRAMEWORK=calabash.framework

if [ ! -e "${FRAMEWORK}" ]; then
  make framework
fi

function install_framework {
  local install_to="${1}/${FRAMEWORK}"
  if [ -e "${install_to}/calabash" ]; then
    rm -rf "${install_to}"
  else
    error "Tried to delete the wrong directory"
    error "  ${install_to}"
    exit 1
  fi
  install_with_ditto "${FRAMEWORK}" "${install_to}"
}

install_framework "../ios-smoke-test-app/CalSmokeApp"
install_framework "../ios-webview-test-app/CalWebViewApp"
install_framework "../ios-iphone-only-app"
install_framework "../Permissions"
install_framework "../DeviceAgent.iOS/Vendor"
