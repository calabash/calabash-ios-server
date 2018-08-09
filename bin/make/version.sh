#!/usr/bin/env bash

source bin/log.sh
source bin/ditto.sh
source bin/simctl.sh

banner "Preparing"

ensure_valid_core_sim_service

XC_PROJECT=calabash.xcodeproj
XC_BUILD_CONFIG=Release

VTOOL_BUILD_DIR=build/version-tool
mkdir -p "${VTOOL_BUILD_DIR}"

INSTALL_PATH=bin/version
rm -rf "${INSTALL_PATH}"

if [ $(gem list -i xcpretty) = "true" ] && [ "${XCPRETTY}" != "0" ]; then
  XC_PIPE='xcpretty -c'
else
  XC_PIPE='cat'
fi
info "Will pipe xcodebuild to: ${XC_PIPE}"

banner "Build Version Tool"

VTOOL="${VTOOL_BUILD_DIR}/Build/Products/${XC_BUILD_CONFIG}/version"

rm -rf "${VTOOL}"

xcrun xcodebuild build \
  -project "${XC_PROJECT}" \
  -scheme "version" \
  -SYMROOT="${VTOOL_BUILD_DIR}" \
  -derivedDataPath "${VTOOL_BUILD_DIR}" \
  -configuration "${XC_BUILD_CONFIG}" \
  -sdk macosx \
  GCC_TREAT_WARNINGS_AS_ERRORS=YES | $XC_PIPE

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE != 0 ]; then
  error "Building version tool for framework failed."
  exit $RETVAL
else
  info "Building version tool for framework succeeded."
fi

banner "Installing Version Tool"

ditto_or_exit "${VTOOL}" "${INSTALL_PATH}"
info "Installed version tool to ${INSTALL_PATH}"

banner "Version Info"

echo "$ ${INSTALL_PATH} --revision ALL"
${INSTALL_PATH} --revision ALL

