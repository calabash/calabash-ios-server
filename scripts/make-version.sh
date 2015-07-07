#!/usr/bin/env bash

# This script is for developer use only.
#
# It is for debugging the version command-line tool.
#
# It is not part of the library generation process.

TARGET_NAME="version"
XC_PROJECT="calabash.xcodeproj"
XC_SCHEME="${TARGET_NAME}"
CAL_BUILD_DIR="${PWD}/build"
DESTINATION="bin/${TARGET_NAME}"

rm -rf "${CAL_BUILD_DIR}"
mkdir -p "${CAL_BUILD_DIR}"

if [ ! -d ./bin ]; then
  echo "INFO: making a ./bin directory"
  mkdir ./bin
fi

if [ -e "${DESTINATION}" ]; then
  echo "INFO: removing ./$DESTINATION"
  rm "${DESTINATION}"
fi

set +o errexit

xcrun xcodebuild \
  -SYMROOT="${CAL_BUILD_DIR}" \
  -derivedDataPath "${CAL_BUILD_DIR}" \
  ONLY_ACTIVE_ARCH=NO \
  -project "${XC_PROJECT}" \
  -scheme "${TARGET_NAME}" \
  -sdk macosx \
  -configuration "${CAL_BUILD_CONFIG}" \
  clean build | xcpretty -c

RETVAL=${PIPESTATUS[0]}

set -o errexit

if [ $RETVAL != 0 ]; then
  echo "FAIL:  could not build"
  exit $RETVAL
else
  echo "INFO: successfully built"
fi

BINARY="${CAL_BUILD_DIR}/Build/Products/Debug/${TARGET_NAME}"

echo "INFO: moving $TARGET_NAME to ${DESTINATION}"
cp "${BINARY}" ${DESTINATION}
