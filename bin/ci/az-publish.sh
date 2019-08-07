#!/usr/bin/env bash

source bin/ditto.sh

set -eo pipefail
CONFIG=Debug

# $1 => SOURCE PATH
# $2 => TARGET NAME
function azupload {
az storage blob upload \
  --container-name ios-test-cloud-agent \
  --if-none-match "*" \
  --file "${1}" \
  --name "${2}"
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

# Evaluate git-sha value
GIT_SHA=$(git rev-parse --verify HEAD | tr -d '\n')

# Evaluate Calabash version
VERSION=$(xcrun strings calabash-dylibs/libCalabashFAT.dylib | grep -E "CALABASH VERSION" | cut -f3- -d" " | tr -d '\n')

az --version

WORKING_DIR="${BUILD_SOURCESDIRECTORY}"

# Upload `calabash.framework.zip`
CALABASH_FRAMEWORK="${WORKING_DIR}/calabash.framework.zip"
zip_with_ditto "${WORKING_DIR}/calabash.framework" "${CALABASH_FRAMEWORK}"
CALABASH_FRAMEWORK_NAME="calabash.framework-${VERSION}-${GIT_SHA}.zip"
azupload "${CALABASH_FRAMEWORK}" "${CALABASH_FRAMEWORK_NAME}"
echo "${CALABASH_FRAMEWORK} artifact uploaded with name ${CALABASH_FRAMEWORK_NAME}"

# Upload `libCalabashFAT.dylib`
CALABASH_FAT="${WORKING_DIR}/calabash-dylibs/libCalabashFAT.dylib"
CALABASH_FAT_NAME="libCalabashFAT-${VERSION}-${GIT_SHA}.dylib"
azupload "${CALABASH_FAT}" "${CALABASH_FAT_NAME}"
echo "${CALABASH_FAT} artifact uploaded with name ${CALABASH_FAT_NAME}"

# Upload `libCalabashARM.dylib`
CALABASH_ARM="${WORKING_DIR}/calabash-dylibs/libCalabashARM.dylib"
CALABASH_ARM_NAME="libCalabashARM-${VERSION}-${GIT_SHA}.dylib"
azupload "${CALABASH_ARM}" "${CALABASH_ARM_NAME}"
echo "${CALABASH_ARM} artifact uploaded with name ${CALABASH_ARM_NAME}"

# Upload `libCalabashSim.dylib`
CALABASH_SIM="${WORKING_DIR}/calabash-dylibs/libCalabashSim.dylib"
CALABASH_SIM_NAME="libCalabashSim-${VERSION}-${GIT_SHA}.dylib"
azupload "${CALABASH_SIM}" "${CALABASH_SIM_NAME}"
echo "${CALABASH_SIM} artifact uploaded with name ${CALABASH_SIM_NAME}"

# Upload `Headers.zip`
HEADERS_ZIP="${WORKING_DIR}/calabash-dylibs/Headers.zip"
HEADERS_ZIP_NAME="libCalabash-Headers-${VERSION}-${GIT_SHA}.zip"
azupload "${HEADERS_ZIP}" "${HEADERS_ZIP_NAME}"
echo "${HEADERS_ZIP} artifact uploaded with name ${HEADERS_ZIP_NAME}"
