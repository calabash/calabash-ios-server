#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

Dir.chdir working_dir do
  install_gem('xcpretty')
  do_system('make clean')
  do_system('make framework')
  do_system('make frank')
  # Cannot run on Travis CI because that rule requires .xcspec files to be
  # copied directly into the target Xcode.app.
  do_system('make dylib')
  do_system('make all')
  do_system('scripts/ci/travis/run-chou-tests.rb')
  # Cannot run on Travis CI because the log output is too large
  do_system('test-make-without-xcpretty.rb')
end
