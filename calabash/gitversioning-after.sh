#!/bin/sh

if [ -z "${1}" ]; then
  echo "FATAL:  you must pass the path to LPGitVersionDefines.h"
  exit 1
fi

LP_INFO_PLIST="${1}"
gitpath=`which git`

echo "INFO: resetting content of ${LP_INFO_PLIST}"
`$gitpath checkout -- ${LP_INFO_PLIST}`
