#!/usr/bin/env bash

if [ -z "${TRAVIS}" ]; then
  echo "FAIL: only run this script on Travis"
  exit 1
fi

if [ "${TRAVIS_SECURE_ENV_VARS}" != "true" ]; then
  echo "INFO: skipping keychain install; non-maintainer activity"
  exit 0
fi

mkdir -p "${HOME}/.test-cloud-dev"

CODE_SIGN_DIR="${HOME}/.test-cloud-dev/test-cloud-dev-ios-keychain"

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

API_TOKEN=`${CODE_SIGN_DIR}/ios/find-xtc-credential.sh api-token | tr -d '\n'`

# Install the API token where briar can find it.
mkdir -p "${HOME}/.test-cloud-dev/test-cloud"
echo $API_TOKEN > "${HOME}/.test-cloud-dev/test-cloud/calabash-ios-ci"

# Bug in Briar. :(
ln -s "${HOME}/.test-cloud-dev" "${HOME}/.xamarin"

# Bug in Briar. :(
touch "${HOME}/.test-cloud-dev/test-cloud/ios-sets.csv"

