#!/usr/bin/env bash

set -e

if [ "${1}" = "--dry-run" ]; then
  DRY_RUN="1"
else
  DRY_RUN="0"
fi

source bin/log-functions.sh
source bin/ditto.sh

DYLIB="calabash-dylibs/libCalabashFAT.dylib"
HEADERS_ZIP="calabash-dylibs/Headers.zip"

if [ ! -e "${DYLIB}" ]; then
  error "Expected ${DYLIB} to exist."
  error "Did you run $ make dylibs first?"
  exit 1
fi

if [ ! -e "${HEADERS_ZIP}" ]; then
  error "Expected ${HEADERS_ZIP} to exist."
  error "Did you run $ make dylibs first?"
  exit 1
fi

GITREV=$(git rev-parse --verify HEAD | tr -d '\n')
ENDPOINT="s3://calabash-files/LPServer/${GITREV}"
DYLIB_ENDPOINT="${ENDPOINT}/libCalabashFAT.dylib"
HEADERS_ENDPOINT="${ENDPOINT}/Headers.zip"

# Waiting on special S3 permissions.
# Until then, use --dry-run
# Jenkins will serve the artifacts.
if [ "${DRY_RUN}" = "1" ]; then
  info "Skipping s3 upload"
  info ""
  info "aws s3 cp ${DYLIB} ${DYLIB_ENDPOINT}"
  info "aws s3 cp ${HEADERS_ZIP} ${HEADERS_ENDPOINT}"
  info ""
else
  aws s3 cp "${DYLIB}" "${DYLIB_ENDPOINT}"
  aws s3 cp "${HEADERS_ZIP}" "${HEADERS_ENDPOINT}"
fi

BRANCH=`git rev-parse --abbrev-ref HEAD | tr -d '\n'`

PRODUCTS_DIR="Products/s3"
mkdir -p "${PRODUCTS_DIR}"
YML_FILE="${PRODUCTS_DIR}/s3.yml"
JSON_FILE="${PRODUCTS_DIR}/s3.json"
TEXT_FILE="${PRODUCTS_DIR}/s3.txt"

### BEGIN REMOVE when S3 permissions available
ditto_or_exit "${DYLIB}" "${PRODUCTS_DIR}"
ditto_or_exit "${HEADERS_ZIP}" "${PRODUCTS_DIR}"

BASE_URL="http://calabash-ci.macminicolo.net:8080/job"
S3_PATH="lastSuccessfulBuild/artifact/Products/s3"
if [ "${BRANCH}" = "develop" ]; then
  JOB_URL="${BASE_URL}/Calabash%20iOS%20Server%20develop"
  DYLIB_ENDPOINT="${JOB_URL}/${S3_PATH}/libCalabashFAT.dylib"
  HEADERS_ENDPOINT="${JOB_URL}/${S3_PATH}/Headers.zip"
elif [ "${BRANCH}" = "master" ]; then
  JOB_URL="${BASE_URL}/Calabash%20iOS%20Server%20master"
  DYLIB_ENDPOINT="${JOB_URL}/${S3_PATH}/libCalabashFAT.dylib"
  HEADERS_ENDPOINT="${JOB_URL}/${S3_PATH}/Headers.zip"
else
  JOB_URL="${BASE_URL}/Calabash%20iOS%20Server%20PR"
  DYLIB_ENDPOINT="${JOB_URL}/${S3_PATH}/libCalabashFAT.dylib"
  HEADERS_ENDPOINT="${JOB_URL}/${S3_PATH}/Headers.zip"
fi
### END REMOVE

DATE=`date +%Y-%m-%dT%H:%M:%S%z | tr -d '\n'`

cat >"${YML_FILE}" <<EOF
branch: ${BRANCH}
git_sha: ${GITREV}
dylib_url: ${DYLIB_ENDPOINT}
headers_zip_url: ${HEADERS_ENDPOINT}
date: ${DATE}
EOF

cat >"${JSON_FILE}" <<EOF
{
  "branch" : "${BRANCH}",
  "git_sha" : "${GITREV}",
  "dylib_url" : "${DYLIB_ENDPOINT}",
  "headers_zip_url" : "${HEADERS_ENDPOINT}",
  "date" : "${DATE}"
}
EOF

echo -n ${DYLIB_ENDPOINT} > "${TEXT_FILE}"
