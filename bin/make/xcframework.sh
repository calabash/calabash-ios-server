#!/usr/bin/env bash

source bin/log.sh
source bin/ditto.sh
source bin/xcode.sh
source bin/simctl.sh

banner "Preparing"

ensure_valid_core_sim_service

set -e -o pipefail

XC_GTE_9=$(xcode_gte_9)
XC_GTE_8=$(xcode_gte_8)

XC_TARGET=calabash
XC_PROJECT=calabash.xcodeproj
XC_SCHEME=calabash
XC_BUILD_CONFIG=Debug

SIM_BUILD_DIR=build/xcframework/sim
mkdir -p "${SIM_BUILD_DIR}"

ARM_BUILD_DIR=build/xcframework/arm
mkdir -p "${ARM_BUILD_DIR}"

VTOOL_BUILD_DIR=build/xcframework/version-tool
mkdir -p "${VTOOL_BUILD_DIR}"

PRODUCTS_DIR=Products/xcframework
rm -rf "${PRODUCTS_DIR}"
mkdir -p "${PRODUCTS_DIR}"

SIM_PRODUCTS_DIR="${PRODUCTS_DIR}/sim"
mkdir -p "${SIM_PRODUCTS_DIR}"

ARM_PRODUCTS_DIR="${PRODUCTS_DIR}/arm"
mkdir -p "${ARM_PRODUCTS_DIR}"

XCFRAMEWORK_PRODUCTS_DIR="${PRODUCTS_DIR}/xcframework"
mkdir -p "${XCFRAMEWORK_PRODUCTS_DIR}"

INSTALLED_FRAMEWORK=calabash.xcframework
rm -rf "${INSTALLED_FRAMEWORK}"

LIBRARY_NAME=libcalabash.a

if [ $(gem list -i xcpretty) = "true" ] && [ "${XCPRETTY}" != "0" ]; then
  XC_PIPE='xcpretty -c'
else
  XC_PIPE='cat'
fi

info "Will pipe xcodebuild to: ${XC_PIPE}"

banner "Building Framework Simulator Library"

SEARCH_PATH="${SIM_BUILD_DIR}/Build/Products"
rm -rf "${SEARCH_PATH}"

xcrun xcodebuild build \
  -SYMROOT="${SIM_BUILD_DIR}" \
  -derivedDataPath "${SIM_BUILD_DIR}" \
  -project ${XC_PROJECT} \
  -scheme ${XC_SCHEME} \
  -configuration "${XC_BUILD_CONFIG}" \
  ARCHS="x86_64 arm64" \
  VALID_ARCHS="x86_64 arm64" \
  ONLY_ACTIVE_ARCH=NO \
  EFFECTIVE_PLATFORM_NAME="-iphonesimulator" \
  -sdk iphonesimulator \
  IPHONEOS_DEPLOYMENT_TARGET=9.0 \
  GCC_TREAT_WARNINGS_AS_ERRORS=NO \
  GCC_GENERATE_TEST_COVERAGE_FILES=NO \
  GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO | $XC_PIPE

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE != 0 ]; then
  error "Building simulator library for framework failed."
  exit $EXIT_CODE
else
  info "Building simulator library for framework succeeded."
fi

SIM_LIBRARY=$(find "${SEARCH_PATH}" -name "libcalabash.a" -type f -print | tr -d '\n')
ditto_or_exit "${SIM_LIBRARY}" "${SIM_PRODUCTS_DIR}/${LIBRARY_NAME}"

HEADERS=$(find "${SEARCH_PATH}" -name "calabashHeaders" -type d -print | tr -d '\n')
ditto_or_exit "${HEADERS}" "${XCFRAMEWORK_PRODUCTS_DIR}/Headers"

banner "Building Framework ARM Library"

if [ "${XC_GTE_9}" = "true" ]; then
  ARM_LIBRARY="${ARM_BUILD_DIR}/Build/Intermediates.noindex/ArchiveIntermediates/calabash/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/${LIBRARY_NAME}"
else
  ARM_LIBRARY="${ARM_BUILD_DIR}/Build/Intermediates/ArchiveIntermediates/${XC_TARGET}/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/${LIBRARY_NAME}"
fi

rm -f "${ARM_LIBRARY}"

xcrun xcodebuild install \
  -project "${XC_PROJECT}" \
  -scheme "${XC_SCHEME}" \
  -SYMROOT="${ARM_BUILD_DIR}" \
  -derivedDataPath "${ARM_BUILD_DIR}" \
  -configuration "${XC_BUILD_CONFIG}" \
  -sdk iphoneos \
  OTHER_CFLAGS="-fembed-bitcode" \
  DEPLOYMENT_POSTPROCESSING=YES \
  ENABLE_BITCODE=YES \
  IPHONE_DEPLOYMENT_TARGET=9.0 \
  GCC_TREAT_WARNINGS_AS_ERRORS=NO \
  GCC_GENERATE_TEST_COVERAGE_FILES=NO \
  GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO | $XC_PIPE

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE != 0 ]; then
  error "Building ARM library for framework failed."
  exit $RETVAL
else
  info "Building ARM library for framework succeeded."
fi

ditto_or_exit "${ARM_LIBRARY}" "${ARM_PRODUCTS_DIR}/${LIBRARY_NAME}"

banner "Build Version Tool"

VTOOL="${VTOOL_BUILD_DIR}/Build/Products/Release/version"

rm -rf "${VTOOL}"

xcrun xcodebuild build \
  -project "${XC_PROJECT}" \
  -scheme "version" \
  -SYMROOT="${VTOOL_BUILD_DIR}" \
  -derivedDataPath "${VTOOL_BUILD_DIR}" \
  -configuration "Release" \
  -sdk macosx \
  GCC_TREAT_WARNINGS_AS_ERRORS=NO | $XC_PIPE

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE != 0 ]; then
  error "Building version tool for framework failed."
  exit $RETVAL
else
  info "Building version tool for framework succeeded."
fi

banner "Creating XCFramework"

XCFRAMEWORK="${XCFRAMEWORK_PRODUCTS_DIR}/calabash.xcframework"

xcrun xcodebuild -create-xcframework \
  -library "${SIM_PRODUCTS_DIR}/${LIBRARY_NAME}" \
  -library "${ARM_PRODUCTS_DIR}/${LIBRARY_NAME}" \
  -output "${XCFRAMEWORK}"

info "Installing XCFramework to ${PWD}/${INSTALLED_FRAMEWORK}"

ditto_or_exit "${XCFRAMEWORK}" "${PWD}/${INSTALLED_FRAMEWORK}"

banner "XCFramework Info"

hash tree 2>/dev/null
if [ $? -eq 0 ]; then
  tree -h calabash.xcframework
else
  ls -hal calabash.xcframework
fi