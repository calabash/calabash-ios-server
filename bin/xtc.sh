#!/usr/bin/env bash

source bin/log.sh

set -e

if [ -z ${1} ]; then
  echo "Usage: ${0} device-set [DeviceAgent-SHA]

Examples:

$ bin/xtc.sh e9232255
$ SKIP_IPA_BUILD=1 SERIES='Args and env' bin/xtc.sh e9232255
$ SERIES='DeviceAgent 2.0' bin/xtc.sh e9232255 48d137d6228ccda303b2a71b0d09e1d0629bf980

The DeviceAgent-SHA optional argument allows tests to be run against any
DeviceAgent that has been uploaded to S3 rather than the current active
DeviceAgent for Test Cloud.

If you need to test local changes to run-loop or Calabash on Test Cloud,
use the BUILD_RUN_LOOP and BUILD_CALABASH env variables.

Responds to these env variables:

        SERIES: the Test Cloud series
SKIP_IPA_BUILD: iff 1, then skip re-building the ipa.
                'make test-ipa' will still be called, so changes in the
                features/ directory will be staged and sent to Test Cloud.
BUILD_RUN_LOOP: iff 1, then rebuild run-loop gem before uploading.
BUILD_RUN_LOOP: iff 1, then rebuild Calabash iOS gem before uploading.

"

  exit 64
fi

CREDS=.xtc-credentials
if [ ! -e "${CREDS}" ]; then
  error "This script requires a ${CREDS} file"
  error "Generating a template now:"
  cat >${CREDS} <<EOF
export XTC_PRODUCTION_API_TOKEN=
export XTC_STAGING_API_TOKEN=
export XTC_USER=
EOF
  cat ${CREDS}
  error "Update the file with your credentials and run again."
  error "Bye."
  exit 1
fi

source "${CREDS}"

# The uninstall/install dance is required to test changes in
# run-loop and calabash-cucumber in Test Cloud
if [ "${BUILD_RUN_LOOP}" = "1" ]; then
  gem uninstall -Vax --force --no-abort-on-dependent run_loop
  (cd ../run_loop; rake install)
fi

if [ "${BUILD_CALABASH}" = "1" ]; then
  gem uninstall -Vax --force --no-abort-on-dependent calabash-cucumber
  (cd ../calabash-ios/calabash-cucumber; rake install)
fi

PREPARE_XTC_ONLY="${SKIP_IPA_BUILD}" make ipa-cal

cd xtc-submit

rm -rf .xtc
mkdir -p .xtc

if [ "${2}" != "" ]; then
  echo "${2}" > .xtc/device-agent-sha
fi

if [ "${SERIES}" = "" ]; then
  SERIES=master
fi

if [ -z $XTC_ENDPOINT ]; then
  API_TOKEN="${XTC_PRODUCTION_API_TOKEN}"
  ENDPOINT="${XTC_PRODUCTION_ENDPOINT}"
  info "Uploading to Production"
else
  API_TOKEN="${XTC_STAGING_API_TOKEN}"
  ENDPOINT="${XTC_STAGING_ENDPOINT}"
  info "Uploading to Staging"
fi

# To submit to a pipeline branch, replace <branch> and append to
# PARAMETERS
PIPELINE="<branch>"

S3_ROOT="https://s3-eu-west-1.amazonaws.com/calabash-files/dylibs/to-test-injection"
LIB_BEETS="${S3_ROOT}/libBetaVulgaris.dylib"
LIB_CABBAGE="${S3_ROOT}/libBrassica.dylib"
LIB_CUCUMBER="${S3_ROOT}/libCucurbits.dylib"
INJECT="inject:${LIB_BEETS};${LIB_CABBAGE};${LIB_CUCUMBER}"

APP_ENV="app_env:ARG_FROM_UPLOADER_FOR_AUT=From-the-CLI-uploader!"

# Required for Test Cloud Scenarios to pass.
# Parameters always needs to include these!
PARAMETERS="${APP_ENV} ${INJECT}"

XTC_ENDPOINT="${ENDPOINT}" \
bundle exec test-cloud submit \
  TestApp.ipa \
  $API_TOKEN \
  --user $XTC_USER \
  --app-name "TestApp" \
  --devices "${1}" \
  --series "${SERIES}" \
  --config cucumber.yml \
  --profile default \
  --dsym-file "TestApp.app.dSYM" \
  --include .xtc \
  --test-parameters ${PARAMETERS}
