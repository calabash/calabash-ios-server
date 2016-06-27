#!/usr/bin/env bash

set -e

cd cucumber

bundle exec cucumber \
  -p simulator \
  --tags @acquaint \
  --format json -o reports/acquaint.json

./xtc-submit-acquaint.rb

