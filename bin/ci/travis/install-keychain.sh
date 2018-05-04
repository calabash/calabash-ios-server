#!/usr/bin/env bash

if [ -z "${TRAVIS}" ]; then
  echo "FAIL: only run this script on Travis"
  exit 1
fi

if [ "${TRAVIS_SECURE_ENV_VARS}" != "true" ]; then
  echo "INFO: skipping keychain install; non-maintainer activity"
  exit 0
fi

mkdir -p "${HOME}/.calabash"

CODE_SIGN_DIR="${HOME}/.calabash/calabash-codesign"

# Requires API token for Calabash CI user
# https://travis-ci.org/calabash/calabash-ios-server/settings
if [ -e "${CODE_SIGN_DIR}" ]; then
  echo "INFO: previous step already cloned the repo"
else
  git clone \
    https://$CI_USER_TOKEN@github.com/calabash/calabash-codesign.git \
    "${CODE_SIGN_DIR}"
fi

(cd "${CODE_SIGN_DIR}" && ios/create-keychain.sh)
(cd "${CODE_SIGN_DIR}" && ios/import-profiles.sh)
