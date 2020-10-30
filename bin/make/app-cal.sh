#!/usr/bin/env bash

source bin/log.sh
source bin/ditto.sh
source bin/simctl.sh
ensure_valid_core_sim_service

# Command line builds alway make a fresh framework
banner "Ensure the calabash.framework"

if [ "${MAKE_FRAMEWORK}" != "0" ]; then
  FRAMEWORK="calabash.framework"
  rm -rf "${FRAMEWORK}"
  make framework
fi

banner "Preparing to build LPTestTarget"

if [ $(gem list -i xcpretty) = "true" ] && [ "${XCPRETTY}" != "0" ]; then
  XC_PIPE='xcpretty -c'
else
  XC_PIPE='cat'
fi
info "Will pipe xcodebuild to: ${XC_PIPE}"

XC_TARGET="LPTestTarget"
XC_PROJECT="calabash.xcodeproj"
XC_CONFIG="CalabashApp"
XC_BUILD_DIR="${PWD}/build/test-target/app-cal"
INSTALL_DIR="Products/test-target/app-cal"

APP="${XC_TARGET}.app"
DSYM="${APP}.dSYM"

INSTALLED_APP="${INSTALL_DIR}/${APP}"
INSTALLED_DSYM="${INSTALL_DIR}/${DSYM}"

rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

info "Prepared install directory ${INSTALL_DIR}"

BUILD_PRODUCTS_DIR="${XC_BUILD_DIR}/Build/Products/${XC_CONFIG}-iphonesimulator"
BUILD_PRODUCTS_APP="${BUILD_PRODUCTS_DIR}/${APP}"
BUILD_PRODUCTS_DSYM="${BUILD_PRODUCTS_DIR}/${DSYM}"

OBJECT_ROOT_DIR="${XC_BUILD_DIR}/Build/Intermediates/${XC_CONFIG}-iphonesimulator"

rm -rf "${BUILD_PRODUCTS_APP}"
rm -rf "${BUILD_PRODUCTS_DSYM}"

info "Prepared archive directory"

banner "Building ${APP}"

COMMAND_LINE_BUILD=1 xcrun xcodebuild \
  -SYMROOT="${XC_BUILD_DIR}" \
  OBJROOT="${OBJECT_ROOT_DIR}" \
  BUILT_PRODUCTS_DIR="${BUILD_PRODUCTS_DIR}" \
  TARGET_BUILD_DIR="${BUILD_PRODUCTS_DIR}" \
  DWARF_DSYM_FOLDER_PATH="${BUILD_PRODUCTS_DIR}" \
  -project "${XC_PROJECT}" \
  -target "${XC_TARGET}" \
  -configuration "${XC_CONFIG}" \
  -sdk iphonesimulator \
  ARCHS="x86_64" \
  VALID_ARCHS="x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  build | $XC_PIPE

EXIT_CODE=${PIPESTATUS[0]}
if [ $EXIT_CODE != 0 ]; then
  error "Building app failed."
  exit $EXIT_CODE
else
  info "Building app succeeded."
fi

banner "Installing"

ditto_or_exit "${BUILD_PRODUCTS_APP}" "${INSTALLED_APP}"
info "Installed ${INSTALLED_APP}"

ditto_or_exit "${BUILD_PRODUCTS_DSYM}" "${INSTALLED_DSYM}"
info "Installed ${INSTALLED_DSYM}"
info "Done!"
