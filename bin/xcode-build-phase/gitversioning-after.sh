#!/usr/bin/env bash

source bin/log.sh

DEFINES_HEADER="calabash/LPGitVersionDefines.h"
if [ ! -e "${DEFINES_HEADER}" ]; then
  info "Defines header does not exist: ${DEFINES_HEADER}"
  info "Nothing to do"
else
  info "Reseting the contents of ${DEFINES_HEADER}"
  git checkout -- "${DEFINES_HEADER}"
fi
