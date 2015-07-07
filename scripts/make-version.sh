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
rm -rf "${CAL_BUILD_DIR}"
mkdir -p "${CAL_BUILD_DIR}"

if [ -e "${TARGET_NAME}" ]; then
  echo "INFO: removing ./$TARGET_NAME"
  rm "${TARGET_NAME}"
fi
xcrun xcodebuild \
  -SYMROOT="${CAL_BUILD_DIR}" \
  -derivedDataPath "${CAL_BUILD_DIR}" \
  ONLY_ACTIVE_ARCH=NO \
  -project "${XC_PROJECT}" \
  -scheme "${TARGET_NAME}" \
  -sdk macosx \
  -configuration "${CAL_BUILD_CONFIG}" \
  clean build

BINARY="${CAL_BUILD_DIR}/Build/Products/Debug/${TARGET_NAME}"

echo "INFO: moving $TARGET_NAME to ./"
cp "${BINARY}" ./
