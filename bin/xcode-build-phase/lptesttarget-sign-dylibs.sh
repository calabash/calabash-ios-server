#!/usr/bin/env bash

# If you see an error like this:
#
# iPhone Developer: ambiguous (matches "iPhone Developer: Person A (2<snip>Q)"
#                                  and "iPhone Developer: Person B (8<snip>F)"
# in /Users/<snip>/Library/Keychains/login.keychain)
#
# Uncomment this line and update it with the correct credentials.
# CODE_SIGN_IDENTITY="iPhone Developer: Person B (8<snip>F)"

set -e

BUNDLE_PATH="${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}"

BAD="${BUNDLE_PATH}/badPlugin.dylib"
EXAMPLE="${BUNDLE_PATH}/examplePlugin.dylib"
EXAMPLE_CAL="${BUNDLE_PATH}/examplePluginCalabash.dylib"
MEMORY="${BUNDLE_PATH}/memoryPlugin.dylib"
MEMORY_CAL="${BUNDLE_PATH}/memoryPluginCalabash.dylib"

if [ -n "${CODE_SIGN_IDENTITY}" ]; then
  xcrun codesign -fs "${CODE_SIGN_IDENTITY}" "${BAD}"
  xcrun codesign -fs "${CODE_SIGN_IDENTITY}" "${EXAMPLE}"
  xcrun codesign -fs "${CODE_SIGN_IDENTITY}" "${EXAMPLE_CAL}"
  xcrun codesign -fs "${CODE_SIGN_IDENTITY}" "${MEMORY}"
  xcrun codesign -fs "${CODE_SIGN_IDENTITY}" "${MEMORY_CAL}"
fi

