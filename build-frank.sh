#!/usr/bin/env bash

# todo add to the Makefile as 'make frank' or 'make' task

# xcpretty will reduce spam and build times
XCPRETTY=`gem list xcpretty -i | tr -d '\n'`
if [ "${XCPRETTY}" = "false" ]; then gem install xcpretty; fi

xcrun xcodebuild -target "frank-calabash" \
                 -configuration Debug \
                 SYMROOT=build \
                 SDKROOT=iphonesimulator \
                 IPHONEOS_DEPLOYMENT_TARGET=5.1.1 | xcpretty -c
