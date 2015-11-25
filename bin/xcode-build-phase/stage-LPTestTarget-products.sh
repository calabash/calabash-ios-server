#!/usr/bin/env bash

# Stages binaries built by Xcode to ./Products/

function info {
  echo "INFO: $1"
}

function error {
  echo "ERROR: $1"
}

function banner {
  echo ""
  echo "######## $1 #######"
  echo ""
}

function ditto_or_exit {
  ditto "${1}" "${2}"
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

# Command line builds already stage binaries to Products/
if [ ! -z $COMMAND_LINE_BUILD ]; then
  exit 0
fi

# Ignore Release configuration
if [ "${CONFIGURATION}" = "Release" ]; then
  exit 0
fi

if [ ${EFFECTIVE_PLATFORM_NAME} = "-iphoneos" ]; then
  if [ ${CONFIGURATION} = "CalabashApp" ]; then
    APP_TARGET_DIR="${SOURCE_ROOT}/Products/test-target/ipa-cal"
  else
    APP_TARGET_DIR="${SOURCE_ROOT}/Products/test-target/ipa"
  fi
else
  if [ ${CONFIGURATION} = "CalabashApp" ]; then
    APP_TARGET_DIR="${SOURCE_ROOT}/Products/test-target/app-cal"
  else
    APP_TARGET_DIR="${SOURCE_ROOT}/Products/test-target/app"
  fi
fi

banner "Preparing"

info "Xcode build detected; will stage binary to $APP_TARGET_DIR"

rm -rf "${APP_TARGET_DIR}"
mkdir -p "${APP_TARGET_DIR}"

info "Cleaned install directory: ${APP_TARGET_DIR}"

APP_SOURCE_PATH="${CONFIGURATION_BUILD_DIR}/${FULL_PRODUCT_NAME}"
APP_TARGET_PATH="${APP_TARGET_DIR}/${FULL_PRODUCT_NAME}"
ditto_or_exit "${APP_SOURCE_PATH}" "${APP_TARGET_PATH}"
info "Copied .app to ${APP_TARGET_DIR}/${FULL_PRODUCT_NAME}"

DSYM_SOURCE_PATH="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
DSYM_TARGET_PATH="${APP_TARGET_DIR}/${DWARF_DSYM_FILE_NAME}"
ditto_or_exit "${DSYM_SOURCE_PATH}" "${DSYM_TARGET_PATH}"
info "Copied .dSYM to ${APP_TARGET_DIR}/${DWARF_DSYM_FILE_NAME}"

if [ ${EFFECTIVE_PLATFORM_NAME} = "-iphoneos" ]; then

  banner "Creating ipa"

  PAYLOAD_DIR="${APP_TARGET_DIR}/Payload"
  mkdir -p "${PAYLOAD_DIR}"
  PAYLOAD_APP="${PAYLOAD_DIR}/${FULL_PRODUCT_NAME}"
  ditto_or_exit "${APP_TARGET_PATH}" "${PAYLOAD_APP}"

  IPA_PATH="${APP_TARGET_DIR}/${TARGET_NAME}.ipa"

  info "Zipping .app to ${IPA_PATH}"
  xcrun ditto -ck --rsrc --sequesterRsrc --keepParent \
    "${PAYLOAD_APP}" \
    "${IPA_PATH}"
  info "Installed .ipa to ${IPA_PATH}"
fi

info "Done!"

