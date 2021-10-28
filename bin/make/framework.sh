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

SIM_BUILD_DIR=build/framework/sim
mkdir -p "${SIM_BUILD_DIR}"

ARM_BUILD_DIR=build/framework/arm
mkdir -p "${ARM_BUILD_DIR}"

VTOOL_BUILD_DIR=build/framework/version-tool
mkdir -p "${VTOOL_BUILD_DIR}"

PRODUCTS_DIR=Products/framework
rm -rf "${PRODUCTS_DIR}"
mkdir -p "${PRODUCTS_DIR}"

SIM_PRODUCTS_DIR="${PRODUCTS_DIR}/sim"
mkdir -p "${SIM_PRODUCTS_DIR}"

ARM_PRODUCTS_DIR="${PRODUCTS_DIR}/arm"
mkdir -p "${ARM_PRODUCTS_DIR}"

FAT_PRODUCTS_DIR="${PRODUCTS_DIR}/fat"
mkdir -p "${FAT_PRODUCTS_DIR}"

INSTALLED_FRAMEWORK=calabash.framework
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
  ARCHS="x86_64" \
  VALID_ARCHS="x86_64" \
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
  exit $EXIT_CODE
else
  info "Building simulator library for framework succeeded."
fi

SIM_LIBRARY=$(find "${SEARCH_PATH}" -name "libcalabash.a" -type f -print | tr -d '\n')
ditto_or_exit "${SIM_LIBRARY}" "${SIM_PRODUCTS_DIR}/${LIBRARY_NAME}"

HEADERS=$(find "${SEARCH_PATH}" -name "calabashHeaders" -type d -print | tr -d '\n')
ditto_or_exit "${HEADERS}" "${FAT_PRODUCTS_DIR}/Headers"

banner "Building Framework ARM Library"

if [ "${XC_GTE_9}" = "true" ]; then
  ARM_LIBRARY="${ARM_BUILD_DIR}/Build/Intermediates.noindex/ArchiveIntermediates/calabash/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/${LIBRARY_NAME}"
else
  ARM_LIBRARY="${ARM_BUILD_DIR}/Build/Intermediates/ArchiveIntermediates/${XC_TARGET}/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/${LIBRARY_NAME}"
fi

rm -f "${ARM_LIBRARY}"

ARCHES="arm64 arm64e"

xcrun xcodebuild install \
  -project "${XC_PROJECT}" \
  -scheme "${XC_SCHEME}" \
  -SYMROOT="${ARM_BUILD_DIR}" \
  -derivedDataPath "${ARM_BUILD_DIR}" \
  -configuration "${XC_BUILD_CONFIG}" \
  ARCHS="${ARCHES}" \
  VALID_ARCHS="${ARCHES}" \
  OTHER_CFLAGS="-fembed-bitcode" \
  DEPLOYMENT_POSTPROCESSING=YES \
  ENABLE_BITCODE=YES \
  IPHONE_DEPLOYMENT_TARGET=9.0 \
  GCC_TREAT_WARNINGS_AS_ERRORS=YES \
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
  GCC_TREAT_WARNINGS_AS_ERRORS=YES | $XC_PIPE

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE != 0 ]; then
  error "Building version tool for framework failed."
  exit $RETVAL
else
  info "Building version tool for framework succeeded."
fi

banner "Creating Framework"

FAT_LIBRARY="${FAT_PRODUCTS_DIR}/calabash"

info "Creating FAT library"

xcrun lipo -create \
  "${SIM_PRODUCTS_DIR}/${LIBRARY_NAME}" \
  "${ARM_PRODUCTS_DIR}/${LIBRARY_NAME}" \
  -o "${FAT_LIBRARY}"

FRAMEWORK="${FAT_PRODUCTS_DIR}/calabash.framework"
mkdir -p "${FRAMEWORK}"

mkdir -p "${FRAMEWORK}/Versions/A"
mkdir -p "${FRAMEWORK}/Versions/A/Resources"

info "Copying files to framework"

ditto_or_exit "${FAT_PRODUCTS_DIR}/Headers" "${FRAMEWORK}/Versions/A/Headers"
ditto_or_exit "${FAT_LIBRARY}" "${FRAMEWORK}/Versions/A/calabash"
ditto_or_exit "${VTOOL}" "${FRAMEWORK}/Versions/A/Resources"

info "Creating symbolic links"

WORKING_DIR="${PWD}"

cd "${FRAMEWORK}"
ln -sfh Versions/Current/Resources Resources
ln -sfh Versions/Current/Headers Headers
ln -sfh Versions/Current/calabash calabash

cd Versions
ln -sfh A Current
ln -sfh A `./A/Resources/version | tr -d '\n'`

cd "${WORKING_DIR}"

info "Installing FAT framework to ${PWD}/${INSTALLED_FRAMEWORK}"

ditto_or_exit "${FRAMEWORK}" "${PWD}/${INSTALLED_FRAMEWORK}"

banner "Framework Info"

hash tree 2>/dev/null
if [ $? -eq 0 ]; then
  tree -h calabash.framework
else
  ls -hal calabash.framework
fi

echo "Built version: `./${INSTALLED_FRAMEWORK}/Resources/version | tr -d '\n'`"
xcrun lipo -info "${INSTALLED_FRAMEWORK}/calabash"

# For dylibs, search for __LLVM
# For static libs (.a) search for bitcode
# Neither is fully reliable because -fembed-bitcode-marker (space for bitcode,
# but no bitcode) would produce a false positive.
#
# If we have trouble with bitcode, we can try:
#
# $ xcodebuild archive
function expect_bitcode {
  xcrun otool -arch $1 -l calabash.framework/calabash | grep 'bitcode' &> /dev/null
  if [ $? -eq 0 ]; then
    echo "calabash.framework/calabash contains bitcode for ${1}"
  else
    echo "calabash.framework/calabash does not contain bitcode for ${1}"
    exit 1
  fi
}

expect_bitcode arm64
expect_bitcode arm64e
