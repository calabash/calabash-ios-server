#!/usr/bin/env bash

set -e

source bin/log.sh

VERSION_ROUTE="calabash/Classes/FranklyServer/Routes/LPVersionRoute.h"
VERSION=$(grep -o  -E '(\d+\.\d+\.\d+(\.pre\d+)?)' ${VERSION_ROUTE} | tr -d "\n")

BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD \
  | tr -d "\n")

if [ "${BRANCH}" != "master" ]; then
  error "Only create tags from the master branch"
  error "The current branch is: ${BRANCH}"
  exit 1
fi

git tag -a "${VERSION}" -m"${VERSION}"
git push origin "${VERSION}"
git branch "tag/${VERSION}" "${VERSION}"
git checkout "tag/${VERSION}"
