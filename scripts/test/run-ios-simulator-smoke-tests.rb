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

  # if calabash.framework exists, it was built in another step
  unless File.exist?('calabash.framework')
    do_system('make framework')
  end

end

calabash_gem_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'calabash-ios'))
calabash_framework = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'calabash.framework'))

Dir.chdir calabash_gem_dir do

  # The name of the CI script that builds the libraries that are included in
  # the calabash-ios gem has changed in the master branch; install-static-libs
  # is the old name.
  if File.exist? 'script/ci/travis/install-static-libs.rb'
    do_system('script/ci/travis/install-static-libs.rb',
              {:pass_msg => 'chou - installed static libs',
               :fail_msg => 'chou - could not install static libs'})
  else
    do_system('script/ci/travis/install-gem-libs.rb',
              {:pass_msg => 'chou - installed gem libraries',
               :fail_msg => 'chou - could not install gem libraries'})
  end


  uninstall_gem('run_loop')
  do_system('rm -rf run_loop')
  do_system('git clone --depth 1 --branch develop --recursive https://github.com/calabash/run_loop')
  run_loop_gem_dir = File.expand_path(File.join(calabash_gem_dir, 'run_loop'))
  Dir.chdir run_loop_gem_dir do
    do_system('bundle install')
    do_system('rake install')
  end

  do_system('script/ci/travis/bundle-install.rb',
            {:pass_msg => 'chou - bundle install worked',
             :fail_msg => 'chou - could not bundle install'})

  do_system('script/ci/travis/install-gem-ci.rb',
            {:pass_msg => 'chou - installing the gem',
             :fail_msg => 'chou - could not install the gem'})

end

chou_working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'ios-smoke-test-app/CalSmokeApp'))

FileUtils.rm_rf("#{chou_working_dir}/calabash.framework")
FileUtils.cp_r(calabash_framework, chou_working_dir)

Dir.chdir chou_working_dir do

  do_system('rm -rf Gemfile*')
  do_system('rm -rf .bundle')

  File.open('Gemfile', 'w') do |file|
    file.write("source 'https://rubygems.org'\n")
    file.write("gem 'run_loop', :github => 'calabash/run_loop', :branch => 'develop'\n")
    file.write("gem 'calabash-cucumber', :github => 'calabash/calabash-ios', :branch => 'develop'\n")
    file.write("gem 'xcpretty', '~> 0.1'\n")
  end

  FileUtils.mkdir_p('.bundle')

  File.open('.bundle/config', 'w') do |file|
    file.write("---\n")
    file.write("BUNDLE_LOCAL__CALABASH-CUCUMBER: \"#{calabash_gem_dir}\"\n")
  end
end

animated_happiness_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'ios-smoke-test-app'))

Dir.chdir animated_happiness_dir do

  do_system('script/ci/travis/build-and-stage-app.sh')

  do_system('script/ci/travis/cucumber-ci.rb --tags ~@no_ci --tags ~@scroll')
end
