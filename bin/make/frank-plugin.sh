#!/usr/bin/env bash

set -e

function info {
  echo "$(tput setaf 2)INFO: $1$(tput sgr0)"
}

function error {
  echo "$(tput setaf 1)ERROR: $1$(tput sgr0)"
}

function banner {
  echo ""
  echo "$(tput setaf 5)######## $1 #######$(tput sgr0)"
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

function xcode_gte_7 {
 XC_MAJOR=`xcrun xcodebuild -version | awk 'NR==1{print $2}' | awk -v FS="." '{ print $1 }'`
 if [ "${XC_MAJOR}" \> "7" -o "${XC_MAJOR}" = "7" ]; then
   echo "true"
 else
   echo "false"
 fi
}

XC_GTE_7=$(xcode_gte_7)

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

if [ "${XCPRETTY}" = "0" ]; then
  USE_XCPRETTY=
else
  USE_XCPRETTY=`which xcpretty | tr -d '\n'`
fi

if [ ! -z ${USE_XCPRETTY} ]; then
  XC_PIPE='xcpretty -c'
else
  XC_PIPE='cat'
fi

banner "Building Frank Plug-in Simulator Library"

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

ditto_or_exit "${SIM_LIBRARY}" "${SIM_PRODUCTS_DIR}/${LIBRARY_NAME}"

banner "Building Frank Plug-in ARM Library"

ARM_LIBRARY_XC71="${ARM_BUILD_DIR}/Build/Intermediates/ArchiveIntermediates/${XC_TARGET}/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/${LIBRARY_NAME}"
rm -rf "${ARM_LIBRARY_XC71}"

ARM_LIBRARY_XC7="${ARM_BUILD_DIR}/Build/Intermediates/ArchiveIntermediates/${XC_TARGET}/IntermediateBuildFilesPath/UninstalledProducts/${LIBRARY_NAME}"
rm -rf "${ARM_LIBRARY_XC7}"

ARM_LIBRARY_XC6="${ARM_BUILD_DIR}/Build/Intermediates/UninstalledProducts/${LIBRARY_NAME}"
rm -rf "${ARM_LIBRARY_XC6}"

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
  ${XC7_FLAGS} -sdk iphoneos \
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

if [ -e "${ARM_LIBRARY_XC71}" ]; then
  ARM_LIBRARY="${ARM_LIBRARY_XC71}"
elif [ -e "${ARM_LIBRARY_XC7}" ]; then
  ARM_LIBRARY="${ARM_LIBRARY_XC7}"
else
  ARM_LIBRARY="${ARM_LIBRARY_XC6}"
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

if [ "${XC_GTE_7}"  = "true" ]; then

  xcrun otool-classic -arch arm64 -l "${INSTALLED_LIBRARY}" | grep -q bitcode
  if [ $? -eq 0 ]; then
    echo "${LIBRARY_NAME} contains bitcode for arm64"
  else
    echo "${LIBRARY_NAME} does not contain bitcode for arm64"
    exit 1
  fi

  xcrun otool-classic -arch armv7s -l "${INSTALLED_LIBRARY}" | grep -q bitcode
  if [ $? -eq 0 ]; then
    echo "${LIBRARY_NAME} contains bitcode for armv7s"
  else
    echo "calabash.framework/calabash does not contain bitcode for armv7s"
    exit 1
  fi

  xcrun otool-classic -arch armv7s -l "${INSTALLED_LIBRARY}" | grep -q bitcode
  if [ $? -eq 0 ]; then
    echo "${LIBRARY_NAME} contains bitcode for armv7"
  else
    echo "${LIBRARY_NAME} does not contain bitcode for armv7"
    exit 1
  fi
fi
