#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

args =
      [
            'test',
            '-SYMROOT=build',
            '-derivedDataPath build',
            '-project calabash.xcodeproj',
            '-scheme calabash-ios-server-tests',
            '-sdk iphonesimulator',
            '-configuration Debug',
            xcpretty_available ? '| xcpretty -c' : ''
      ]

Dir.chdir(working_dir) do
  do_system "xcrun xcodebuild #{args.join(' ')}"
end
