#!/usr/bin/env ruby
require 'fileutils'

target = ARGV[0]
valid_args = ['sim', 'device']

if ARGV.count !=1 or not valid_args.include? target
  puts "FAIL: Usage: #{__FILE__} {sim | device}"
  exit 1
end

xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

target_arg = 'calabash-dylib'

if target == 'sim'
  sdk = 'iphonesimulator'
  arches = 'i386 x86_64'
else
  sdk = 'iphoneos'
  arches = 'armv7 armv7s arm64'
end

# dylib target does _not_ create necessary directories
FileUtils.mkdir_p "./build/Debug-#{sdk}"

args =
      [
            '-project calabash.xcodeproj',
            "-scheme \"#{target_arg}\"",
            '-configuration Debug',
            "ARCHS=\"#{arches}\"",
            "VALID_ARCHS=\"#{arches}\"",
            'ONLY_ACTIVE_ARCH=NO',
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
