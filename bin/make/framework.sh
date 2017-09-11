#!/usr/bin/env bash

source bin/log.sh

set -e

function xcode_gte_7 {
 XC_MAJOR=`xcrun xcodebuild -version | awk 'NR==1{print $2}' | awk -v FS="." '{ print $1 }'`
 if [ "${XC_MAJOR}" \> "7" -o "${XC_MAJOR}" = "7" ]; then
   echo "true"
 else
   echo "false"
 fi
}

XC_GTE_7=$(xcode_gte_7)

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

banner "Building Framework Simulator Library"

SEARCH_PATH="${SIM_BUILD_DIR}/Build/Products"
rm -rf "${SEARCH_PATH}"

xcrun xcodebuild build \
  -SYMROOT="${SIM_BUILD_DIR}" \
  -derivedDataPath "${SIM_BUILD_DIR}" \
  -project ${XC_PROJECT} \
  -scheme ${XC_SCHEME} \
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

if [ -z ${TRAVIS+x} ]; then
  hash tree 2>/dev/null
  if [ $? -eq 0 ]; then
    tree -h calabash.framework
  else
    ls -hal calabash.framework
  fi
fi

echo "Built version: `./${INSTALLED_FRAMEWORK}/Resources/version | tr -d '\n'`"
lipo -info "${INSTALLED_FRAMEWORK}/calabash"

if [ "${XC_GTE_7}"  = "true" ]; then

  xcrun otool-classic -arch arm64 -l calabash.framework/calabash | grep -q bitcode
  if [ $? -eq 0 ]; then
    echo "calabash.framework/calabash contains bitcode for arm64"
  else
    echo "calabash.framework/calabash does not contain bitcode for arm64"
    exit 1
  fi

  xcrun otool-classic -arch armv7s -l calabash.framework/calabash | grep -q bitcode
  if [ $? -eq 0 ]; then
    echo "calabash.framework/calabash contains bitcode for armv7s"
  else
    echo "calabash.framework/calabash does not contain bitcode for armv7s"
    exit 1
  fi

  xcrun otool-classic -arch armv7 -l calabash.framework/calabash | grep -q bitcode
  if [ $? -eq 0 ]; then
    echo "calabash.framework/calabash contains bitcode for armv7"
  else
    echo "calabash.framework/calabash does not contain bitcode for armv7"
    exit 1
  fi
fi

