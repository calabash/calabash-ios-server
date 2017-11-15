#!/usr/bin/env bash

source bin/log.sh

DEFINES_HEADER="calabash/LPGitVersionDefines.h"
if [ ! -e "${DEFINES_HEADER}" ]; then
  error "${DEFINES_HEADER} file needs to exist"
  exit 1
fi

info "Reseting the contents of ${DEFINES_HEADER}"
git checkout -- "${DEFINES_HEADER}"
