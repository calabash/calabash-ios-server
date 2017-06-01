#!/usr/bin/env bash

set +e

# Force Xcode 7 CoreSimulator env to be loaded so xcodebuild does not fail.
export DEVELOPER_DIR=/Xcode/7.3.1/Xcode.app/Contents/Developer

for try in {1..4}; do
  xcrun simctl help &>/dev/null
  sleep 1.0
done

set -e

function info {
  echo "$(tput setaf 2)INFO: $1$(tput sgr0)"
}

function error {
  echo "$(tput setaf 1)ERROR: $1$(tput sgr0)"
}

function banner {
  echo ""
  echo "$(tput setaf 5)######## $1 #######$(tput sgr0)"
  echo ""
}

make clean

banner "Install Code Signing Keychain"
bin/ci/jenkins/install-keychain.sh

bundle update

# Make libraries
make framework
make frank
bin/ci/jenkins/make-dylibs.sh

bin/ci/jenkins/make-ipa.sh
bundle exec bin/test/test-cloud.rb

bundle install

banner "Run Tests"
bundle exec bin/test/xctest.rb
bundle exec bin/test/cucumber.rb

banner "Test iPhone 6+ touch coordinates"
bundle exec bin/test/acquaint.rb

# Skip s3 upload with --dry-run until S3 credentials are available
bin/ci/jenkins/s3-publish.sh --dry-run
