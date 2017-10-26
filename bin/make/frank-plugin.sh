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

XC_TARGET=calabash-plugin-for-frank
XC_PROJECT=calabash.xcodeproj
XC_SCHEME=calabash-plugin-for-frank
XC_BUILD_CONFIG=Debug

SIM_BUILD_DIR=build/frank-plugin/sim
mkdir -p "${SIM_BUILD_DIR}"

ARM_BUILD_DIR=build/frank-plugin/arm
mkdir -p "${ARM_BUILD_DIR}"

PRODUCTS_DIR=Products/frank-plugin
rm -rf "${PRODUCTS_DIR}"
mkdir -p "${PRODUCTS_DIR}"

SIM_PRODUCTS_DIR="${PRODUCTS_DIR}/sim"
mkdir -p "${SIM_PRODUCTS_DIR}"

ARM_PRODUCTS_DIR="${PRODUCTS_DIR}/arm"
mkdir -p "${ARM_PRODUCTS_DIR}"

FAT_PRODUCTS_DIR="${PRODUCTS_DIR}/fat"
mkdir -p "${FAT_PRODUCTS_DIR}"

INSTALLED_LIBRARY=libFrankCalabash.a
rm -rf "${INSTALLED_LIBRARY}"

LIBRARY_NAME=libcalabash-plugin-for-frank.a

hash xcpretty 2>/dev/null
if [ $? -eq 0 ] && [ "${XCPRETTY}" != "0" ]; then
  XC_PIPE='xcpretty -c'
else
  XC_PIPE='cat'
fi

info "Will pipe xcodebuild to: ${XC_PIPE}"

banner "Building Frank Plug-in Simulator Library"

SEARCH_PATH="${SIM_BUILD_DIR}/Build/Products"
rm -rf "${SEARCH_PATH}"

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
  IPHONEOS_DEPLOYMENT_TARGET=6.0 \
  GCC_TREAT_WARNINGS_AS_ERRORS=YES \
  GCC_GENERATE_TEST_COVERAGE_FILES=NO \
  GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO | $XC_PIPE

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE != 0 ]; then
  error "Building simulator library for frank plug-in failed."
  exit $RETVAL
else
  info "Building simulator library for frank plug-in succeeded."
fi

SIM_LIBRARY=$(find "${SEARCH_PATH}" -name "${LIBRARY_NAME}" -type f -print | tr -d '\n')
ditto_or_exit "${SIM_LIBRARY}" "${SIM_PRODUCTS_DIR}/${LIBRARY_NAME}"

banner "Building Frank Plug-in ARM Library"

if [ "${XC_GTE_9}" = "true" ]; then
  ARM_LIBRARY="${ARM_BUILD_DIR}/Build/Intermediates.noindex/ArchiveIntermediates/${XC_TARGET}/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/${LIBRARY_NAME}"
else
  ARM_LIBRARY="${ARM_BUILD_DIR}/Build/Intermediates/ArchiveIntermediates/${XC_TARGET}/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/${LIBRARY_NAME}"
fi

rm -f "${ARM_LIBRARY}"


if [ "${XC_GTE_7}" = "true" ]; then
  XC7_FLAGS="OTHER_CFLAGS=\"-fembed-bitcode\" DEPLOYMENT_POSTPROCESSING=YES ENABLE_BITCODE=YES"
fi

xcrun xcodebuild install \
  -project "${XC_PROJECT}" \
  -scheme "${XC_SCHEME}" \
  -SYMROOT="${ARM_BUILD_DIR}" \
  -derivedDataPath "${ARM_BUILD_DIR}" \
  -configuration "${XC_BUILD_CONFIG}" \
  ARCHS="armv7 armv7s arm64" \
  VALID_ARCHS="armv7 armv7s arm64" \
  ONLY_ACTIVE_ARCH=NO \
  OTHER_CFLAGS="-fembed-bitcode" \
  DEPLOYMENT_POSTPROCESSING=YES \
  ENABLE_BITCODE=YES \
  -sdk iphoneos \
  IPHONE_DEPLOYMENT_TARGET=6.0 \
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

banner "Installing Frank Plug-in"

FAT_LIBRARY="${FAT_PRODUCTS_DIR}/${INSTALLED_LIBRARY}"

xcrun lipo -create \
  "${SIM_PRODUCTS_DIR}/${LIBRARY_NAME}" \
  "${ARM_PRODUCTS_DIR}/${LIBRARY_NAME}" \
  -o "${FAT_LIBRARY}"

info "Installing to ${PWD}/${INSTALLED_LIBRARY}"

ditto_or_exit "${FAT_LIBRARY}" "${PWD}/${INSTALLED_LIBRARY}"

banner "Frank Plug-in Info"

VERSION=`xcrun strings "${INSTALLED_LIBRARY}" | grep -E 'CALABASH VERSION' | head -1 | grep -oEe '\d+\.\d+\.\d+' | tr -d '\n'`
echo "Built version:  $VERSION"
lipo -info "${INSTALLED_LIBRARY}"

# For dylibs, search for __LLVM
# For static libs (.a) search for bitcode
# Neither is fully reliable because -fembed-bitcode-marker (space for bitcode,
# but no bitcode) would produce a false positive.
#
# If we have trouble with bitcode, we can try:
#
# $ xcodebuild archive
function expect_bitcode {
  xcrun otool -arch $1 -l "${INSTALLED_LIBRARY}" | grep 'bitcode' &> /dev/null
  if [ $? -eq 0 ]; then
    echo "${INSTALLED_LIBRARY} contains bitcode for ${1}"
  else
    echo "${INSTALLED_LIBRARY} does not contain bitcode for ${1}"
    exit 1
  fi
}

expect_bitcode arm64
expect_bitcode armv7
expect_bitcode armv7s

