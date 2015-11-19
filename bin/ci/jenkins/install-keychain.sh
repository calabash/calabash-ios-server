#!/usr/bin/env bash

if [ -z "${JENKINS_HOME}" ]; then
  echo "FAIL: only run this script on Jenkins"
  exit 1
fi

mkdir -p "${HOME}/.calabash"

CODE_SIGN_DIR="${HOME}/.calabash/calabash-codesign"

rm -rf "${CODE_SIGN_DIR}"

if [ -e "${CODE_SIGN_DIR}" ]; then
  # Previous step or run checked out this file.
  (cd "${CODE_SIGN_DIR}" && git reset --hard)
  (cd "${CODE_SIGN_DIR}" && git checkout master)
  (cd "${CODE_SIGN_DIR}" && git pull)
else
  git clone \
    git@github.com:calabash/calabash-codesign.git \
    "${CODE_SIGN_DIR}"
fi

(cd "${CODE_SIGN_DIR}" && ios/create-keychain.sh)
(cd "${CODE_SIGN_DIR}" && ios/import-profiles.sh)

API_TOKEN=`${CODE_SIGN_DIR}/ios/find-xtc-credential.sh api-token | tr -d '\n'`

# Install the API token where briar can find it.
mkdir -p "${HOME}/.calabash/test-cloud"
echo $API_TOKEN > "${HOME}/.calabash/test-cloud/calabash-ios-ci"

# Bug in Briar. :(
ln -s "${HOME}/.calabash" "${HOME}/.xamarin"

# Bug in Briar. :(
touch "${HOME}/.calabash/test-cloud/ios-sets.csv"

