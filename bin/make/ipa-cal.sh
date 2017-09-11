#!/usr/bin/env bash

source bin/log.sh
source bin/ditto.sh
source bin/simctl.sh
ensure_valid_core_sim_service

set -e

# Command line builds alway make a fresh framework
banner "Ensure the calabash.framework"

FRAMEWORK="calabash.framework"
rm -rf "${FRAMEWORK}"
make framework

banner "Preparing to build LPTestTarget"

hash xcpretty 2>/dev/null
if [ $? -eq 0 ] && [ "${XCPRETTY}" != "0" ]; then
  XC_PIPE='xcpretty -c'
else
  XC_PIPE='cat'
fi
info "Will pipe xcodebuild to: ${XC_PIPE}"

XC_TARGET="LPTestTarget"
XC_PROJECT="calabash.xcodeproj"
XC_SCHEME="${XC_TARGET}"
XC_CONFIG=CalabashApp
XC_BUILD_DIR="build/test-target/ipa-cal/LPTestTarget"

APP="${XC_TARGET}.app"
DSYM="${APP}.dSYM"
IPA="${XC_TARGET}.ipa"

INSTALL_DIR="Products/test-target/ipa-cal"
INSTALLED_APP="${INSTALL_DIR}/${APP}"
INSTALLED_DSYM="${INSTALL_DIR}/${DSYM}"
INSTALLED_IPA="${INSTALL_DIR}/${IPA}"

rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

info "Prepared install directory ${INSTALL_DIR}"

BUILD_PRODUCTS_DIR="${XC_BUILD_DIR}/Build/Products/${XC_CONFIG}-iphoneos"
BUILD_PRODUCTS_APP="${BUILD_PRODUCTS_DIR}/${APP}"
BUILD_PRODUCTS_DSYM="${BUILD_PRODUCTS_DIR}/${DSYM}"

rm -rf "${BUILD_PRODUCTS_APP}"
rm -rf "${BUILD_PRODUCTS_DSYM}"

info "Prepared archive directory"

banner "Building ${IPA}"

if [ -z "${CODE_SIGN_IDENTITY}" ]; then
  COMMAND_LINE_BUILD=1 xcrun xcodebuild \
    -SYMROOT="${XC_BUILD_DIR}" \
    -derivedDataPath "${XC_BUILD_DIR}" \
    -project "${XC_PROJECT}" \
    -scheme "${XC_TARGET}" \
    -configuration "${XC_CONFIG}" \
    -sdk iphoneos \
    ARCHS="armv7 armv7s arm64" \
    VALID_ARCHS="armv7 armv7s arm64" \
    ONLY_ACTIVE_ARCH=NO \
    build | $XC_PIPE
else
  COMMAND_LINE_BUILD=1 xcrun xcodebuild \
    CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
    -SYMROOT="${XC_BUILD_DIR}" \
    -derivedDataPath "${XC_BUILD_DIR}" \
    -project "${XC_PROJECT}" \
    -scheme "${XC_TARGET}" \
    -configuration "${XC_CONFIG}" \
    -sdk iphoneos \
    ARCHS="armv7 armv7s arm64" \
    VALID_ARCHS="armv7 armv7s arm64" \
    ONLY_ACTIVE_ARCH=NO \
    build | $XC_PIPE
fi

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE != 0 ]; then
  error "Building ipa failed."
  exit $EXIT_CODE
else
  info "Building ipa succeeded."
fi

banner "Installing"

ditto_or_exit "${BUILD_PRODUCTS_APP}" "${INSTALLED_APP}"
info "Installed ${INSTALLED_APP}"

PAYLOAD_DIR="${INSTALL_DIR}/Payload"
mkdir -p "${PAYLOAD_DIR}"

ditto_or_exit "${INSTALLED_APP}" "${PAYLOAD_DIR}/${APP}"

xcrun ditto -ck --rsrc --sequesterRsrc --keepParent \
  "${PAYLOAD_DIR}" \
  "${INSTALLED_IPA}"

info "Installed ${INSTALLED_IPA}"

ditto_or_exit "${BUILD_PRODUCTS_DSYM}" "${INSTALLED_DSYM}"
info "Installed ${INSTALLED_DSYM}"

banner "Code Signing Details"

DETAILS=`xcrun codesign --display --verbose=2 ${INSTALLED_APP} 2>&1`

echo "$(tput setaf 4)$DETAILS$(tput sgr0)"

banner "Preparing for XTC Submit"

XTC_DOTENV="cucumber/.env"

if [ ! -e "${XTC_DOTENV}" ]; then
  info "No cucumber/.env file found."
  info "A .env file is required for submitting to Test Cloud"
  info "If you are a maintainer, you should have a .env!"
  info "Ask jmoody for details"
  info "Done!"
  exit 0
fi

XTC_DIR="${HOME}/.calabash/xtc/calabash-ios-server/submit"
rm -rf "${XTC_DIR}"
mkdir -p "${XTC_DIR}"

ditto_or_exit cucumber/features "${XTC_DIR}/features"
info "Copied features to ${XTC_DIR}/"

ditto_or_exit cucumber/config/xtc-profiles.yml "${XTC_DIR}/cucumber.yml"
info "Copied cucumber/config/xtc-profiles.yml to ${XTC_DIR}/"

ditto_or_exit "${INSTALLED_IPA}" "${XTC_DIR}/"
info "Copied ${IPA} to ${XTC_DIR}/"

ditto_or_exit "${INSTALLED_DSYM}" "${XTC_DIR}/${DSYM}"
info "Copied ${DSYM} to ${XTC_DIR}/"

info "Done!"

