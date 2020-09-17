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

XC_TARGET=calabash-dylib
XC_PROJECT=calabash.xcodeproj
XC_SCHEME=calabash-dylib
XC_BUILD_CONFIG=Debug

SIM_BUILD_DIR=build/dylib/sim
mkdir -p "${SIM_BUILD_DIR}"

ARM_BUILD_DIR=build/dylib/arm
mkdir -p "${ARM_BUILD_DIR}"

PRODUCTS_DIR=Products/dylib
rm -rf "${PRODUCTS_DIR}"
mkdir -p "${PRODUCTS_DIR}"

SIM_PRODUCTS_DIR="${PRODUCTS_DIR}/sim"
mkdir -p "${SIM_PRODUCTS_DIR}"

ARM_PRODUCTS_DIR="${PRODUCTS_DIR}/arm"
mkdir -p "${ARM_PRODUCTS_DIR}"

FAT_PRODUCTS_DIR="${PRODUCTS_DIR}/fat"
mkdir -p "${FAT_PRODUCTS_DIR}"

INSTALL_DIR=calabash-dylibs
rm -rf "${INSTALL_DIR}"

LIBRARY_NAME=calabash-dylib.dylib

if [ $(gem list -i xcpretty) = "true" ] && [ "${XCPRETTY}" != "0" ]; then
  XC_PIPE='xcpretty -c'
else
  XC_PIPE='cat'
fi
info "Will pipe xcodebuild to: ${XC_PIPE}"

banner "Building Dylib Simulator Library"

SIM_BUILD_PRODUCTS_DIR="${SIM_BUILD_DIR}/Build/Products/${XC_BUILD_CONFIG}-iphonesimulator"
SIM_LIBRARY="${SIM_BUILD_PRODUCTS_DIR}/${LIBRARY_NAME}"
rm -rf "${SIM_LIBRARY}"

# Xcode issues non-fatal warnings re: this directory is missing.
# Xcode will eventually create the directory, but if we create it
# ourselves, we can suppress the warnings.
mkdir -p "${SIM_BUILD_PRODUCTS_DIR}"

xcrun xcodebuild build \
  -project ${XC_PROJECT} \
  -scheme ${XC_SCHEME} \
  -SYMROOT="${SIM_BUILD_DIR}" \
  -derivedDataPath "${SIM_BUILD_DIR}" \
  -configuration "${XC_BUILD_CONFIG}" \
  ARCHS="i386 x86_64" \
  VALID_ARCHS="i386 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  EFFECTIVE_PLATFORM_NAME="-iphonesimulator" \
  -sdk iphonesimulator \
  IPHONEOS_DEPLOYMENT_TARGET=9.0 \
  GCC_TREAT_WARNINGS_AS_ERRORS=YES \
  GCC_GENERATE_TEST_COVERAGE_FILES=NO \
  GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO | $XC_PIPE

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE != 0 ]; then
  error "Building simulator library for framework failed."
  exit $RETVAL
else
  info "Building simulator library for framework succeeded."
fi

ditto_or_exit "${SIM_LIBRARY}" "${SIM_PRODUCTS_DIR}/${LIBRARY_NAME}"

HEADERS="${SIM_BUILD_DIR}/Build/Products/Debug-iphonesimulator/usr/local/include"

banner "Building Dylib ARM Library"

if [ "${XC_GTE_9}" = "true" ]; then
  ARM_LIBRARY="${ARM_BUILD_DIR}/Build/Intermediates.noindex/ArchiveIntermediates/calabash-dylib/BuildProductsPath/Debug-iphoneos/${LIBRARY_NAME}"
else
  ARM_LIBRARY="${ARM_BUILD_DIR}/Build/Intermediates/ArchiveIntermediates/calabash-dylib/InstallationBuildProductsLocation/usr/local/lib/${LIBRARY_NAME}"
fi

rm -f "${ARM_LIBRARY}"

ARCHES="armv7 armv7s arm64 arm64e"

xcrun xcodebuild install \
  -project "${XC_PROJECT}" \
  -scheme "${XC_SCHEME}" \
  -SYMROOT="${ARM_BUILD_DIR}" \
  -derivedDataPath "${ARM_BUILD_DIR}" \
  -configuration "${XC_BUILD_CONFIG}" \
  ARCHS="${ARCHES}" \
  VALID_ARCHS="${ARCHES}" \
  DEPLOYMENT_POSTPROCESSING=YES \
  IPHONE_DEPLOYMENT_TARGET=8.0 \
  GCC_TREAT_WARNINGS_AS_ERRORS=YES \
  GCC_GENERATE_TEST_COVERAGE_FILES=NO \
  GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO | $XC_PIPE

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE != 0 ]; then
  error "Building ARM library for framework failed."
  exit $EXIT_CODE
else
  info "Building ARM library for framework succeeded."
fi

ditto_or_exit "${ARM_LIBRARY}" "${ARM_PRODUCTS_DIR}/${LIBRARY_NAME}"

banner "Installing Dylibs"

FAT_LIBRARY="${FAT_PRODUCTS_DIR}/libCalabashFAT.dylib"

xcrun lipo -create \
  "${SIM_PRODUCTS_DIR}/${LIBRARY_NAME}" \
  "${ARM_PRODUCTS_DIR}/${LIBRARY_NAME}" \
  -o "${FAT_LIBRARY}"

TARGET_LIB="${PWD}/${INSTALL_DIR}/libCalabashFAT.dylib"
info "Installing FAT library to ${TARGET_LIB}"
ditto_or_exit "${FAT_LIBRARY}" "${TARGET_LIB}"

TARGET_LIB="${PWD}/${INSTALL_DIR}/libCalabashSim.dylib"
info "Installing simulator library to ${TARGET_LIB}"
ditto_or_exit "${SIM_PRODUCTS_DIR}/${LIBRARY_NAME}" "${TARGET_LIB}"

TARGET_LIB="${PWD}/${INSTALL_DIR}/libCalabashARM.dylib"
info "Installing ARM library to ${TARGET_LIB}"
ditto_or_exit "${ARM_PRODUCTS_DIR}/${LIBRARY_NAME}" "${TARGET_LIB}"

info "Installing Headers to ${PWD}/${INSTALL_DIR}"
ditto_or_exit "${HEADERS}" "${INSTALL_DIR}/Headers"
zip_with_ditto "${INSTALL_DIR}/Headers" "${INSTALL_DIR}/Headers.zip"

banner "Dylib Code Signing"

if [ "${KEYCHAIN}" = "" ]; then
  KEYCHAIN="${HOME}/.calabash/Calabash.keychain"
fi

if [ -e "${KEYCHAIN}" ]; then
  info "Will resign with keychain: ${KEYCHAIN}"
else
  error "Expected keychain at path:"
  error "  ${KEYCHAIN}"
  error "If you are signing with the Calabash.keychain,"
  error "pull the latest from GitHub and recreate the keychain."
  exit 1
fi

if [ "${CODE_SIGN_IDENTITY}" = "" ]; then
  CODE_SIGN_IDENTITY="iPhone Developer: Karl Krukow (YTTN6Y2QS9)"
fi

set +e
xcrun security find-certificate \
  -Z -c "${CODE_SIGN_IDENTITY}" \
  "${KEYCHAIN}" > /dev/null

if [ "$?" = "0" ]; then
  info "Will resign with identity: ${CODE_SIGN_IDENTITY}"
else
  error "Expected to find identity in keychain:"
  error "            KEYCHAIN: ${KEYCHAIN}"
  error "  CODE_SIGN_IDENTITY: ${CODE_SIGN_IDENTITY}"
  error ""
  error "These identities are in the keychain:"
  xcrun security find-identity -v -p codesigning "${KEYCHAIN}"
  exit 1
fi
set -e

info "Resiging the device dylib"

xcrun codesign \
  --verbose \
  --force \
  --sign "${CODE_SIGN_IDENTITY}" \
  --keychain "${KEYCHAIN}" \
  "${INSTALL_DIR}/libCalabashARM.dylib"

info "Resiging the FAT dylib"
xcrun codesign \
  --verbose \
  --force \
  --sign "${CODE_SIGN_IDENTITY}" \
  --keychain "${KEYCHAIN}" \
  "${INSTALL_DIR}/libCalabashFAT.dylib"

banner "Dylib Info"

VERSION=`xcrun strings "${INSTALL_DIR}/libCalabashSim.dylib" | grep -E 'CALABASH VERSION' | head -1 | grep -oEe '\d+\.\d+\.\d+' | tr -d '\n'`
echo "Built version:  $VERSION"

lipo -info "${INSTALL_DIR}/libCalabashARM.dylib"
lipo -info "${INSTALL_DIR}/libCalabashSim.dylib"
lipo -info "${INSTALL_DIR}/libCalabashFAT.dylib"
