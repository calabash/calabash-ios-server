#!/bin/sh

if [ -z "${1}" ]; then
  echo "FATAL:  you must pass the path to LPGitVersionDefines.h"
  exit 1
fi

LP_INFO_PLIST="${1}"
gitpath=`which git`
GITREV=`$gitpath rev-parse --short HEAD`
GITBRANCH=`git rev-parse --abbrev-ref HEAD`
GITREMOTEORIGIN=`git config --get remote.origin.url`


echo "/************************** README *****************************" > "${LP_INFO_PLIST}"
echo "" >> "${LP_INFO_PLIST}"
echo " DO NOT MANUALLY CHANGE THE CONTENTS OF THIS FILE" >> "${LP_INFO_PLIST}"
echo "" >> "${LP_INFO_PLIST}"
echo " the contents are updated before compile time with the following defines:" >> "${LP_INFO_PLIST}"
echo "" >> "${LP_INFO_PLIST}"
echo " #define LP_GIT_SHORT_REVISION <rev>    // ex. @\"4fdb203\"" >> "${LP_INFO_PLIST}"
echo " #define LP_GIT_BRANCH <branch>         // ex. @\"0.9.x\"" >> "${LP_INFO_PLIST}"
echo " #define LP_GIT_REMOTE_ORIGIN <origin>  // ex. @\"git@github.com:jmoody/calabash-ios-server.git\"" >> "${LP_INFO_PLIST}"
echo "" >> "${LP_INFO_PLIST}"
echo " after compilation, the contents are reset using: " >> "${LP_INFO_PLIST}"
echo " git co -- calabash/LPGitVersionDefines.h >>" "${LP_INFO_PLIST}"
echo "" >> "${LP_INFO_PLIST}"
echo " to see how this file is managed, navigate to the calabash target and look at:" >> "${LP_INFO_PLIST}"
echo "" >> "${LP_INFO_PLIST}"
echo " 1. Run Script - git versioning 1 of 2" >> "${LP_INFO_PLIST}"
echo " 2. Run Script - git versioning 2 of 2" >> "${LP_INFO_PLIST}"
echo "" >> "${LP_INFO_PLIST}"
echo " and these scripts:" >> "${LP_INFO_PLIST}"
echo "" >> "${LP_INFO_PLIST}"
echo " 3. gitversioning-before.sh" >> "${LP_INFO_PLIST}"
echo " 4. gitversioning-after.sh" >> "${LP_INFO_PLIST}"
echo "" >> "${LP_INFO_PLIST}"
echo "****************************************************************/" >> "${LP_INFO_PLIST}"



echo "INFO: setting the GIT_SHORT_REVISION = ${GITREV} in ${LP_INFO_PLIST}"
echo "#define LP_GIT_SHORT_REVISION @\"${GITREV}\"" >> "${LP_INFO_PLIST}"
echo "INFO: setting the GIT_BRANCH = ${GITBRANCH} in ${LP_INFO_PLIST}"
echo "#define LP_GIT_BRANCH @\"${GITBRANCH}\"" >> "${LP_INFO_PLIST}"
echo "INFO: setting the GIT_REMOTE_ORIGIN = ${GITREMOTEORIGIN} in ${LP_INFO_PLIST}"
echo "#define LP_GIT_REMOTE_ORIGIN @\"${GITREMOTEORIGIN}\"" >> "${LP_INFO_PLIST}"
