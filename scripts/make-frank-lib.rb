#!/usr/bin/env ruby

target = ARGV[0]
valid_args = ['sim', 'device']

if ARGV.count !=1 or not valid_args.include? target
  puts "FAIL: Usage: #{__FILE__} {sim | device}"
  exit 1
end

xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

if target == 'sim'
  target_arg = 'frank-calabash'
  sdk = 'iphonesimulator'
else
  target_arg = 'frank-calabash-device'
  sdk = 'iphoneos'
end

args =
      [
            '-project calabash.xcodeproj',
            "-scheme \"#{target_arg}\"",
            '-configuration Debug',
            'SYMROOT=build',
            '-derivedDataPath build',
            "-sdk #{sdk}",
            'IPHONEOS_DEPLOYMENT_TARGET=5.1.1',
            xcpretty_available ? '| xcpretty -c' : ''
      ].join(' ')

system "xcrun xcodebuild #{args}"
exit $?.exitstatus
