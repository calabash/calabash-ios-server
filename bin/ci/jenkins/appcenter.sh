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

CAL_CODESIGN="${HOME}/.calabash/calabash-codesign"
if [ -e "${CAL_CODESIGN}" ]; then
  AC_TOKEN=$("${CAL_CODESIGN}/apple/find-appcenter-credential.sh" api-token)
else
  if [ "${AC_TOKEN}" = "" ]; then
    error "Expected calabash-codesign to be installed to:"
    error "  ${CAL_CODESIGN}"
    error "or AC_TOKEN environment variable to be defined."
    error ""
    error "Need an AppCenter API Token to proceed"
    exit 1
  fi
fi

info "Will use token: ${AC_TOKEN}"

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
