#!/usr/bin/env ruby

xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

args =
      [
            "-target \"version\"",
            '-configuration Debug',
            'SYMROOT=build',
            xcpretty_available ? '| xcpretty -c' : ''
      ].join(' ')

system "xcrun xcodebuild #{args}"
exit $?.exitstatus

