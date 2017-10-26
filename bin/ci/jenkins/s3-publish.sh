#!/usr/bin/env bash

set -e

METADATA_VERSION="1.0.0"

if [[ "${1}" != "release" &&  "${1}" != "adhoc" ]]; then
  echo "Usage: bin/s3-publish {release | adhoc} [--dry-run]"
  echo ""
  echo "The first argument controls how the SHA in the S3 url is created."
  echo ""
  echo "release => s3://ios-lpserver/<SHA> will be the current git SHA"
  echo "  adhoc => s3://ios-lpserver/<SHA> will be the SHA of the dylib"
  exit 1
fi

if echo $* | grep -q -e "--dry-run"
then
  DRY_RUN="1"
else
  DRY_RUN="0"
fi

source bin/log.sh
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

DATE=$(date +%Y-%m-%dT%H:%M:%S%z | tr -d '\n')
GITREV=$(git rev-parse --verify HEAD | tr -d '\n')
BRANCH=$(git rev-parse --abbrev-ref HEAD | tr -d '\n')
REMOTE=$(git config --get remote.origin.url | tr -d '\n')
USER=$(whoami)
MACHINE=$(scutil --get ComputerName | tr -d '\n')
VERSION=$(xcrun strings calabash-dylibs/libCalabashFAT.dylib |
  grep -E "CALABASH VERSION" | cut -f3- -d" " | tr -d '\n')

if [ "${1}" = "release" ]; then
  SHA="${GITREV}"
else
  SHA=$(/usr/bin/shasum "${DYLIB}" | awk '{print $1}' |  tr -d '\n')
fi

mkdir -p tmp
PROVENANCE=tmp/provenance.json
rm -f "${PROVENANCE}"

cat >"${PROVENANCE}" <<EOF
{
  "branch" : "${BRANCH}",
  "remote" : "${REMOTE}",
  "git_sha" : "${GITREV}",
  "user" : "${USER}",
  "date" : "${DATE}",
  "machine" : "${MACHINE}",
  "dylib-version" : "${VERSION}",
  "meta-data-version" : "${METADATA_VERSION}"
}
EOF

ENDPOINT="s3://calabash-files/ios-lpserver/${SHA}"
DYLIB_ENDPOINT="${ENDPOINT}/libCalabashFAT.dylib"
HEADERS_ENDPOINT="${ENDPOINT}/Headers.zip"
PROVENANCE_ENDPOINT="${ENDPOINT}/provenance.json"

if [ "${DRY_RUN}" = "1" ]; then
  info "Skipping s3 upload"
  info ""
  info "aws s3 cp ${DYLIB} ${DYLIB_ENDPOINT}"
  info "aws s3 cp ${HEADERS_ZIP} ${HEADERS_ENDPOINT}"
  info "aws s3 cp ${PROVENANCE} ${PROVENANCE_ENDPOINT}"
  info ""
else
  aws s3 cp "${DYLIB}" "${DYLIB_ENDPOINT}"
  aws s3 cp "${HEADERS_ZIP}" "${HEADERS_ENDPOINT}"
  aws s3 cp "${PROVENANCE}" "${PROVENANCE_ENDPOINT}"
fi

PRODUCTS_DIR="Products/s3"
mkdir -p "${PRODUCTS_DIR}"
YML_FILE="${PRODUCTS_DIR}/s3.yml"
JSON_FILE="${PRODUCTS_DIR}/s3.json"
TEXT_FILE="${PRODUCTS_DIR}/s3.txt"

cat >"${YML_FILE}" <<EOF
branch: ${BRANCH}
remote: ${REMOTE}
git_sha: ${GITREV}
user: ${USER}
date: ${DATE}
machine: ${MACHINE}
dylib-version: ${VERSION}
dylib_url: ${DYLIB_ENDPOINT}
headers_zip_url: ${HEADERS_ENDPOINT}
provenance_url: ${PROVENANCE_URL}
EOF

cat >"${JSON_FILE}" <<EOF
{
  "branch" : "${BRANCH}",
  "remote" : "${REMOTE}",
  "git_sha" : "${GITREV}",
  "user" : "${USER}",
  "date" : "${DATE}",
  "machine" : "${MACHINE}",
  "dylib-version" : "${VERSION}",
  "meta-data-version" : "${METADATA_VERSION}"
  "dylib_url" : "${DYLIB_ENDPOINT}",
  "headers_zip_url" : "${HEADERS_ENDPOINT}",
  "provenance_url" : "${PROVENANCE_URL}"
}
EOF

echo -n ${DYLIB_ENDPOINT} > "${TEXT_FILE}"
