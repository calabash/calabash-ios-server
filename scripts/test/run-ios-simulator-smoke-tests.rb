#!/usr/bin/env ruby
require 'fileutils'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

uninstall_gem('calabash-cucumber')


Dir.chdir working_dir do

  do_system('rm -rf calabash-ios')

  do_system('git clone --depth 1 --branch develop --recursive https://github.com/calabash/calabash-ios')

  do_system('rm -rf ios-smoke-test-app')

  do_system('git clone --depth 1 --recursive https://github.com/calabash/ios-smoke-test-app.git')

  do_system('rm -rf run_loop')

  do_system("git clone --depth 1 --recursive https://github.com/calabash/run_loop")

  unless File.exist?('calabash.framework')
    do_system("make clean")
    do_system('make framework')
  end
end

calabash_gem_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'calabash-ios'))
run_loop_gem_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "run_loop"))
calabash_framework = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'calabash.framework'))

smoke_test_working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'ios-smoke-test-app/CalSmokeApp'))

FileUtils.rm_rf("#{smoke_test_working_dir}/calabash.framework")
FileUtils.cp_r(calabash_framework, smoke_test_working_dir)

Dir.chdir smoke_test_working_dir do

  do_system('rm -rf Gemfile*')
  do_system('rm -rf .bundle')

  other_gems = File.join("config", "xtc-other-gems.rb")

  File.open('Gemfile', 'w') do |file|
    file.write("source 'https://rubygems.org'\n")
    file.write("gem 'run_loop', :github => 'calabash/run_loop', :branch => 'develop'\n")
    file.write("gem 'calabash-cucumber', :github => 'calabash/calabash-ios', :branch => 'develop'\n")
    File.readlines(other_gems).each do |line|
      file.write(line)
    end
  end

  FileUtils.mkdir_p('.bundle')

  File.open('.bundle/config', 'w') do |file|
    file.write("---\n")
    file.write("BUNDLE_LOCAL__CALABASH-CUCUMBER: \"#{calabash_gem_dir}\"\n")
    file.write("BUNDLE_LOCAL__RUN_LOOP: \"#{run_loop_gem_dir}\"\n")
  end
end

smoke_test_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'ios-smoke-test-app'))

Dir.chdir smoke_test_root do
  do_system("script/ci/travis/run.rb --tags @travis")
end

