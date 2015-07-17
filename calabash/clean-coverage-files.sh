#!/usr/bin/env bash

# Called by XCTest Run Script Build Phase to clear coverage files
# which, when corrupt, can cause XCTest console spam.
# https://github.com/specta/specta/issues/167
INTERMEDIATES_DIR="${BUILD_DIR}/../Intermediates"

if [ -e "${INTERMEDIATES_DIR}" ]; then
  find ${INTERMEDIATES_DIR} -type f -name "*.gcda" -exec rm -rf {} \;
fi
