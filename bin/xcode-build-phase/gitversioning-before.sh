#!/usr/bin/env bash

source bin/log.sh

DEFINES_HEADER="calabash/LPGitVersionDefines.h"
if [ ! -e "${DEFINES_HEADER}" ]; then
  error "${DEFINES_HEADER} file needs to exist"
  exit 1
fi

GITBRANCH=$(git rev-parse --abbrev-ref HEAD | tr -d "\n")
GITREMOTEORIGIN=$(git config --get remote.origin.url | tr -d "\n")
BUILD_DATE=$(date "+%Y-%M-%d %H:%S:%S %z" | tr -d "\n")
GITREV=$(git rev-parse --short HEAD | tr -d "\n")

if [[ $(git status --porcelain) ]]; then
  info "Cannot generate git SHA because there are uncommitted changes"
  info "Will generate a SHA from the project source files"
  mkdir -p tmp
  rm -f tmp/calabash.tar
  tar -cf tmp/calabash.tar ./calabash calabash.xcodeproj/project.pbxproj bin
  SHA="$(shasum tmp/calabash.tar | cut -d" " -f1 | tr -d "\n")-dirty"
  rm tmp/calabash.tar
else
  SHA=$(git rev-parse HEAD | tr -d "\n")
fi

cat > "${DEFINES_HEADER}" << EOF
/************************** README *****************************"

DO NOT MANUALLY CHANGE THE CONTENTS OF THIS FILE

The contents are updated before compile time with the following defines:

#define LP_GIT_SHORT_REVISION <rev>
#define LP_GIT_BRANCH <branch>
#define LP_GIT_REMOTE_ORIGIN <origin>
#define LP_SERVER_BUILD_DATE <date in seconds>

# This is one of two values:
# 1. If the local git repo is clean, then this value is the commit SHA
# 2. If the local git repo is not clean, it is the shasum of a .tar of
#    the calabash/ calabash.xcodeproj/project.pbxproj bin/ sources.
#define LP_SERVER_ID_KEY_VALUE @"LPSERVERID=<sha>

After compilation, the contents of this file are reset using:

git co -- calabash/LPGitVersionDefines.h

To see how this file is managed, navigate to the calabash target and look at:

1. Run Script - git versioning 1 of 2
2. Run Script - git versioning 2 of 2

and these scripts:

3. bin/xcode-build-phase/gitversioning-before.sh
4. bin/xcode-build-phase/gitversioning-after.sh

****************************************************************/

#define LP_GIT_SHORT_REVISION @"${GITREV}"
#define LP_GIT_REVISION_KEY_VALUE @"LPGITREV=${SHA}"
#define LP_GIT_BRANCH @"${GITBRANCH}"
#define LP_GIT_REMOTE_ORIGIN @"${GITREMOTEORIGIN}"
#define LP_SERVER_BUILD_DATE "${BUILD_DATE}"
#define LP_SERVER_ID_VALUE "${SHA}"
#define LP_SERVER_ID_KEY_VALUE "LPSERVERID=${SHA}"
EOF
