#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

Dir.chdir working_dir do
  install_gem('xcpretty')
  do_system('make clean')
  scripts_dir = File.expand_path(File.join(working_dir, 'scripts'))
  Dir.chdir scripts_dir do
    do_system 'ruby make-framework.rb'
  end
  do_system('make')
  do_system('make frank')
  do_system('scripts/ci/travis/run-chou-tests.rb')
  do_system('test-make-without-xcpretty.rb')
end
