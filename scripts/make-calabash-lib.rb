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
              xcpretty_available ? '| xcpretty -c' : ''
        ].join(' ')

  system "xcrun xcodebuild #{args}"
  exit $?.exitstatus
else
  if target == 'sim'
    target_arg = 'calabash-simulator'
    sdk = 'iphonesimulator'
    arches = 'i386 x86_64'
  else
    target_arg = 'calabash-device'
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
              'IPHONEOS_DEPLOYMENT_TARGET=5.1.1',
              xcpretty_available ? '| xcpretty -c' : ''
        ].join(' ')

  system "xcrun xcodebuild #{args}"
  exit $?.exitstatus
end
