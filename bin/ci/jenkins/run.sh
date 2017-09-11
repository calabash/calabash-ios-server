#!/usr/bin/env bash

source bin/log.sh
source bin/simctl.sh
ensure_valid_core_sim_service

set -e

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

info "Skipping Acquaint tests cannot be run because dylib injection is failing"
info "on macOS Sierra and Xcode 8.3.3."
#bundle exec bin/test/acquaint.rb

# Skip s3 upload with --dry-run until S3 credentials are available
bin/ci/jenkins/s3-publish.sh --dry-run
