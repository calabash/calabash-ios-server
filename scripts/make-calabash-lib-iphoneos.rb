#!/usr/bin/env ruby

xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

args =
      [
            "-target \"calabash-device\"",
            '-configuration Debug',
            'SYMROOT=build',
            'SDKROOT=iphoneos',
            'IPHONEOS_DEPLOYMENT_TARGET=5.1.1',
            xcpretty_available ? '| xcpretty -c' : ''
      ].join(' ')

system "xcrun xcodebuild #{args}"
exit $?.exitstatus