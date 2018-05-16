#!/usr/bin/env bash

source "bin/log.sh"
source "bin/xcode.sh"

set +e
hash appcenter 2>/dev/null
if [ $? -eq 0 ]; then
  info "Using $(appcenter --version)"
  set -e
else
  error "appcenter cli is not installed."
  error ""
  error "$ brew update; brew install npm"
  error "$ npm install -g appcenter-cli"
  error ""
  error "Then try again."
  exit 1
fi

if [ "${AC_TOKEN}" = "" ]; then
  KEYCHAIN="${HOME}/.calabash/Calabash.keychain"

  if [ ! -e "${KEYCHAIN}" ]; then
    echo "Cannot find AppCenter token: there is no Calabash.keychain"
    echo "  ${KEYCHAIN}"
    exit 1
  fi

  if [ ! -e "${HOME}/.calabash/find-keychain-credential.sh" ]; then
    echo "Cannot find AppCenter token: no find-keychain-credential.sh script"
    echo "  ${HOME}/.calabash/find-keychain-credential.sh"
    exit 1
  fi

  info "Fetching AppCenter token from Calabash.keychain"
  AC_TOKEN=$("${HOME}/.calabash/find-keychain-credential.sh" api-token)
fi

WORKSPACE="${HOME}/.calabash/xtc/calabash-ios-server/submit"

if [ ! -e "${WORKSPACE}" ]; then
  error "Expected this directory to exist:"
  error "  ${WORKSPACE}"
  error "Did you forget to run 'make ipa-cal'?"
  exit 1
else
  info "Using existing workspace: ${WORKSPACE}"
fi

if [ "${SERIES}" = "" ]; then
  SERIES=master
fi

appcenter test run calabash \
  --app "App-Center-Test-Cloud/LPTestTarget-iOS" \
  --devices "App-Center-Test-Cloud/latest-releases-ios" \
  --app-path "${WORKSPACE}/LPTestTarget.ipa" \
  --test-series "${SERIES}" \
  --project-dir "${WORKSPACE}" \
  --config-path "${WORKSPACE}/cucumber.yml" \
  --token "${AC_TOKEN}" \
  --dsym-dir "${WORKSPACE}/LPTestTarget.app.dSYM" \
  --async \
  --disable-telemetry
