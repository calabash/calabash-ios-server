#!/usr/bin/env ruby

target = ARGV[0]
valid_args = ['sim', 'device']

if ARGV.count !=1 or not valid_args.include? target
  puts "FAIL: Usage: #{__FILE__} {sim | device}"
  exit 1
end

xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

target_arg = 'calabash-plugin-for-frank'

if target == 'sim'
  sdk = 'iphonesimulator'
  arches = 'i386 x86_64'
else
  sdk = 'iphoneos'
  arches = 'armv7 armv7s arm64'
end

args =
      [
            '-project calabash.xcodeproj',
            "-scheme \"#{target_arg}\"",
            '-configuration Debug',
            'SYMROOT=build',
            '-derivedDataPath build',
            "ARCHS=\"#{arches}\"",
            "VALID_ARCHS=\"#{arches}\"",
            'ONLY_ACTIVE_ARCH=NO',
            "-sdk #{sdk}",
            # Minimum version for ENABLE_BITCODE
            'IPHONEOS_DEPLOYMENT_TARGET=6.0',
            'GCC_TREAT_WARNINGS_AS_ERRORS=YES',
            'GCC_GENERATE_TEST_COVERAGE_FILES=NO',
            'GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO',
            xcpretty_available ? '| xcpretty -c' : ''
      ].join(' ')

system "xcrun xcodebuild #{args}"
exit $?.exitstatus
