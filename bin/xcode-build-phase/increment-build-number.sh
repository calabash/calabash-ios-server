#!/usr/bin/env bash

set -e

HEADER="${PROJECT_DIR}/${INFOPLIST_PREFIX_HEADER}"
PLIST="${PROJECT_DIR}/${INFOPLIST_FILE}"
touch "${PLIST}"

if [ -f "${HEADER}" ]; then
  set +e
  LINE=`cat "${HEADER}" | grep "define PRODUCT_BUILD_NUMBER"`
  OLD_BUILD_NUMBER=`echo "${LINE}" | awk -F' ' '{printf $3}'`

  if [ "$?" != "0" ]; then
    NEW_BUILD_NUMBER="1"
  else
    NEW_BUILD_NUMBER=$(($OLD_BUILD_NUMBER + 1))
  fi
  set -e
else
  NEW_BUILD_NUMBER="1"
fi

cat > "${HEADER}" <<EOF
/*
DO NOT MANUALLY CHANGE THE CONTENTS OF THIS FILE

The PRODUCT_BUILD_NUMBER is advanced for every
build of ${PRODUCT_NAME}.

This file should not be added to version control.
*/

#define PRODUCT_BUILD_NUMBER ${NEW_BUILD_NUMBER}
EOF

