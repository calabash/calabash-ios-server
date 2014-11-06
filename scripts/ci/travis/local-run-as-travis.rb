#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'test-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

# noinspection RubyStringKeysInHashInspection
env_vars =
      {
            'TRAVIS' => '1',
      }

Dir.chdir working_dir do
  install_gem('xcpretty')
  do_system('make clean', {:env_vars => env_vars})
  do_system('make framework', {:env_vars => env_vars})
  do_system('make frank', {:env_vars => env_vars})
  # Cannot run on Travis CI because that rule requires .xcspec files to be
  # copied directly into the target Xcode.app.
  do_system('make dylibs', {:env_vars => env_vars})
  do_system('make no-offending-symbols', {:env_vars => env_vars})
  do_system('make all', {:env_vars => env_vars})
  do_system('scripts/test/xctest.rb', {:env_vars => env_vars})
  do_system('scripts/test/run-chou-tests.rb', {:env_vars => env_vars})
end
