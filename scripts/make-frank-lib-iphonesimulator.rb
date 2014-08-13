#!/usr/bin/env ruby

xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

args =
      [
            "-target \"frank-calabash\"",
            '-configuration Debug',
            'SYMROOT=build',
            'SDKROOT=iphonesimulator',
            'IPHONEOS_DEPLOYMENT_TARGET=5.1.1',
            xcpretty_available ? '| xcpretty -c' : ''
      ].join(' ')

system "xcrun xcodebuild #{args}"
exit $?.exitstatus
