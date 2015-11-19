#!/usr/bin/env bash

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

banner "Install codesigning keychain"
bin/ci/jenkins/install-keychain.sh
bundle install
make framework
make frank
bin/ci/jenkins/make-dylibs

banner "Submit to Test Cloud"
bin/ci/jenkins/make-ipa.sh
bundle exec bin/test/test-cloud.rb

