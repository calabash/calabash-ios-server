#!/usr/bin/env bash

function info {
  echo "INFO: $1"
}

function error {
  echo "ERROR: $1"
}

function banner {
  echo ""
  echo "######## $1 #######"
  echo ""
}

# Ignore all configurations but CalabashApp
if [ "${CONFIGURATION}" != "CalabashApp" ]; then
  exit 0
fi

FRAMEWORK="${SOURCE_ROOT}/calabash.framework"

if [ -d "${FRAMEWORK}" ]; then
  info "Calabash framework exists; nothing to do"
else
  info "Calabash framework is missing; building it"
  make framework
fi

