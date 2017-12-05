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

#define LP_GIT_SHORT_REVISION @"2c6cd17"
#define LP_GIT_REVISION_KEY_VALUE @"LPGITREV=d3cb50f94c08a36c88793fbf795b4fe2b5ce4a70-dirty"
#define LP_GIT_BRANCH @"feature/conditionally-start-lpserver"
#define LP_GIT_REMOTE_ORIGIN @"git@github.com:calabash/calabash-ios-server.git"
#define LP_SERVER_BUILD_DATE "2017-44-23 10:57:57 +0100"
#define LP_SERVER_ID_VALUE "d3cb50f94c08a36c88793fbf795b4fe2b5ce4a70-dirty"
#define LP_SERVER_ID_KEY_VALUE "LPSERVERID=d3cb50f94c08a36c88793fbf795b4fe2b5ce4a70-dirty"
