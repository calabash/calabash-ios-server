#!/usr/bin/env bash

# This is necessary because we want the sha of the app to change
# when a new version of the calabash.framework is linked.  If only
# the framework changes, the sha does not change. :(

PLIST="${SOURCE_ROOT}/LPTestTarget/change-sha.plist"

DATE=`date +%Y%m%d_%H%M%S | tr -d '\n'`

xcrun defaults write "${PLIST}" LPBuildDate $DATE

