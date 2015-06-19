#!/usr/bin/env ruby

target = ARGV[0]
valid_args = ['sim', 'device', 'version']

if ARGV.count !=1 or not valid_args.include? target
  puts "FAIL: Usage: #{__FILE__} {sim | device | version}"
  exit 1
end

xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

if target == 'version'

  args =
        [
              "-target \"version\"",
              '-configuration Debug',
              'SYMROOT=build',
              'GCC_TREAT_WARNINGS_AS_ERRORS=YES',
              xcpretty_available ? '| xcpretty -c' : ''
        ].join(' ')

  system "xcrun xcodebuild #{args}"
  exit $?.exitstatus
else
  target_arg = 'calabash'

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
              "ARCHS=\"#{arches}\"",
              "VALID_ARCHS=\"#{arches}\"",
              'ONLY_ACTIVE_ARCH=NO',
              '-derivedDataPath build',
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
end
