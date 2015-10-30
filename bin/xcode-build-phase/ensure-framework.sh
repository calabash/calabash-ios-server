#!/usr/bin/env bash

function info {
  echo "INFO: $1"
}

# Command line builds are responsible for ensuring framework
if [ ! -z $COMMAND_LINE_BUILD ]; then
  exit 0
fi

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

