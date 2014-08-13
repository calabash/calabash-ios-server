#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

Dir.chdir working_dir do
  uninstall_gem('xcpretty')
  do_system('make clean')
  do_system('make')
  do_system('make frank')
end
