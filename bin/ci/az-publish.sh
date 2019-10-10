#!/usr/bin/env bash

source bin/ditto.sh
source bin/xcode.sh

set -eo pipefail

# $1 => SOURCE PATH
# $2 => TARGET NAME
function azupload {
  az storage blob upload \
    --container-name ios-test-cloud-agent \
    --file "${1}" \
    --name "${2}"
  echo "${1} artifact uploaded with name ${2}"
}

# Pipeline Variables are set through the AzDevOps UI
# See also the ./azdevops-pipeline.yml
if [[ -z "${AZURE_STORAGE_ACCOUNT}" ]]; then
  echo "AZURE_STORAGE_ACCOUNT is required"
  exit 1
fi

if [[ -z "${AZURE_STORAGE_KEY}" ]]; then
  echo "AZURE_STORAGE_KEY is required"
  exit 1
fi

if [[ -z "${AZURE_STORAGE_CONNECTION_STRING}" ]]; then
  echo "AZURE_STORAGE_CONNECTION_STRING is required"
  exit 1
fi

if [ -e ./.azure-credentials ]; then
  source ./.azure-credentials
fi

if [ "${BUILD_SOURCESDIRECTORY}" != "" ]; then
  WORKING_DIR="${BUILD_SOURCESDIRECTORY}"
else
  WORKING_DIR="."
fi

# Evaluate git-sha value
GIT_SHA=$(git rev-parse --verify HEAD | tr -d '\n')

# Evaluate Calabash version
VERSION=$(xcrun strings calabash-dylibs/libCalabashFAT.dylib | grep -E "CALABASH VERSION" | cut -f3- -d" " | tr -d '\n')

# Evaluate the Xcode version used to build artifacts
XC_VERSION=$(xcode_version)

# Evaluate calabash.framework SHASUM256
FRAMEWORK_SHASUM256=$(shasum --algorithm 256 ${WORKING_DIR}/calabash.framework/calabash | cut -d " " -f 1)

# Evaluate dylibFAT SHASUM256
DYLIBFAT_SHASUM256=$(shasum --algorithm 256 ${WORKING_DIR}/calabash-dylibs/libCalabashFAT.dylib | cut -d " " -f 1)

az --version

if [[ $BUILD_SOURCEBRANCH == refs/tags/* ]]; then
  # Upload `calabash.framework.zip`
  CALABASH_FRAMEWORK="${WORKING_DIR}/calabash.framework.zip"
  zip_with_ditto "${WORKING_DIR}/calabash.framework" "${CALABASH_FRAMEWORK}"
  CALABASH_FRAMEWORK_NAME="calabash.framework-${VERSION}-Xcode-${XC_VERSION}-${GIT_SHA}.zip"
  azupload "${CALABASH_FRAMEWORK}" "${CALABASH_FRAMEWORK_NAME}"

  # Upload `libCalabashFAT.dylib`
  CALABASH_FAT="${WORKING_DIR}/calabash-dylibs/libCalabashFAT.dylib"
  CALABASH_FAT_NAME="libCalabashFAT-${VERSION}-Xcode-${XC_VERSION}-${GIT_SHA}.dylib"
  azupload "${CALABASH_FAT}" "${CALABASH_FAT_NAME}"

  # Upload `libCalabashARM.dylib`
  CALABASH_ARM="${WORKING_DIR}/calabash-dylibs/libCalabashARM.dylib"
  CALABASH_ARM_NAME="libCalabashARM-${VERSION}-Xcode-${XC_VERSION}-${GIT_SHA}.dylib"
  azupload "${CALABASH_ARM}" "${CALABASH_ARM_NAME}"

  # Upload `libCalabashSim.dylib`
  CALABASH_SIM="${WORKING_DIR}/calabash-dylibs/libCalabashSim.dylib"
  CALABASH_SIM_NAME="libCalabashSim-${VERSION}-Xcode-${XC_VERSION}-${GIT_SHA}.dylib"
  azupload "${CALABASH_SIM}" "${CALABASH_SIM_NAME}"

  # Upload `Headers.zip`
  HEADERS_ZIP="${WORKING_DIR}/calabash-dylibs/Headers.zip"
  HEADERS_ZIP_NAME="libCalabash-Headers-${VERSION}-Xcode-${XC_VERSION}-${GIT_SHA}.zip"
  azupload "${HEADERS_ZIP}" "${HEADERS_ZIP_NAME}"

  ARTIFACT_NAME="release"

elif [[ $BUILD_SOURCEBRANCH == "develop" ]]; then
  ARTIFACT_NAME="develop"
fi

if [[ -n "${ARTIFACT_NAME}" ]]; then
  # Create and upload `{develop|release}.txt`
  ARTIFACT_TXT="${WORKING_DIR}/${ARTIFACT_NAME}.txt"
  {
    echo "format_version:1.0"
    echo "product_version:$VERSION"
    echo "Xcode_version:$XC_VERSION"
    echo "commit_sha:$GIT_SHA"
    echo "framework_shasum256:$FRAMEWORK_SHASUM256"
    echo "dylibFAT_shasum256:$DYLIBFAT_SHASUM256"
    echo "framework_zip:$CALABASH_FRAMEWORK_NAME"
    echo "dylibFAT_id:$CALABASH_FAT_NAME"
  } > $ARTIFACT_TXT
  ARTIFACT_TXT_NAME="${ARTIFACT_NAME}.txt"
  azupload "$ARTIFACT_TXT" "$ARTIFACT_TXT_NAME"

  # Create and upload `{develop|release}.json`
  ARTIFACT_JSON="${WORKING_DIR}/${ARTIFACT_NAME}.json"
  echo "[\"1.0\", \"$VERSION\", \"$XC_VERSION\", \"$GIT_SHA\", \"$FRAMEWORK_SHASUM256\",
      \"$DYLIBFAT_SHASUM256\", \"$CALABASH_FRAMEWORK_NAME\", \"$CALABASH_FAT_NAME\"]" |
  jq '. | {format_version:.[0], product_version:.[1], Xcode_version:.[2], commit_sha:.[3], framework_shasum256:.[4],
      dylibFAT_shasum256:.[5], framework_zip:.[6], dylibFAT:.[7]}' > $ARTIFACT_JSON
  ARTIFACT_JSON_FILE="${ARTIFACT_NAME}.json"
  azupload "$ARTIFACT_JSON" "$ARTIFACT_JSON_NAME"
fi