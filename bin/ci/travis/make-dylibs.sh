#!/usr/bin/env bash

if [ -z "${TRAVIS}" ]; then
  echo "FAIL: only run this script on Travis"
  exit 1
fi

if [ "${TRAVIS_SECURE_ENV_VARS}" != "true" ]; then
  echo "INFO: Skipping 'make dylibs'; non-maintainer activity"
  exit 0
fi

make dylibs

