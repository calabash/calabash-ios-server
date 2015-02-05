#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

# See the note below about why we cannot use xcpretty.
#xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

XCODE_MAJOR_VERSION=`xcrun -k xcodebuild -version | tr -d "\n" | cut -c 7`.chomp
if XCODE_MAJOR_VERSION == '5'
  target_simulator_name = 'iPhone Retina (4-inch)'
else
  target_simulator_name = 'iPhone 5s'
end

args =
      [
            'clean',
            'test',
            '-SYMROOT=build',
            '-derivedDataPath build',
            '-project calabash.xcodeproj',
            '-scheme calabash-ios-server-tests',
            "-destination 'platform=iOS Simulator,name=#{target_simulator_name},OS=latest'",
            '-sdk iphonesimulator',
            '-configuration Debug'
      # See the note below about why we cannot use xcpretty.
      # xcpretty_available ? '| xcpretty -c' : ''
      ]

Dir.chdir(working_dir) do
  terminate_all_sims
  # Would like to use xcpretty here, but there are two problems.
  #
  # 1. xcodebuild + test + xcpretty does _not_ return a non-zero exit code
  #    when there is a compilation error.
  # 2. We cannot use xcodebuild _without_ xcpretty on Travis CI; there is too
  #    much output to stdout and the build will fail.
  #
  # To compensate, we don't use xcpretty and suppress xcodebuild output.
  cmd = "xcrun xcodebuild #{args.join(' ')} > /dev/null"
  do_system(cmd,
            {:pass_msg => 'XCTests passed',
             :fail_msg => 'XCTests failed'})
end
