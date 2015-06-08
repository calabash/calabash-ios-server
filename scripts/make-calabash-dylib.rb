#!/usr/bin/env ruby
require 'fileutils'

target = ARGV[0]
valid_args = ['sim', 'device']

if ARGV.count !=1 or not valid_args.include? target
  puts "FAIL: Usage: #{__FILE__} {sim | device}"
  exit 1
end

xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

if target == 'sim'
  target_arg = 'calabash-dylib-simulator'
  sdk = 'iphonesimulator'
else
  target_arg = 'calabash-dylib-device'
  sdk = 'iphoneos'
end

# dylib target does _not_ create necessary directories
FileUtils.mkdir_p "./build/Debug-#{sdk}"

args =
      [
            '-project calabash.xcodeproj',
            "-scheme \"#{target_arg}\"",
            '-configuration Debug',
            '-derivedDataPath build',
            'SYMROOT=build',
            "-sdk #{sdk}",
            # Minimum for supporting ENABLE_BITCODE
            'IPHONEOS_DEPLOYMENT_TARGET=6.0',
            'GCC_TREAT_WARNINGS_AS_ERRORS=YES',
            'GCC_GENERATE_TEST_COVERAGE_FILES=NO',
            'GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO',
            xcpretty_available ? '| xcpretty -c' : ''
      ].join(' ')

system "xcrun xcodebuild #{args}"
exit $?.exitstatus
