#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test-helpers'))
require 'run_loop'
require 'retriable'
require 'retriable/version'

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

XCODE_MAJOR_VERSION=`xcrun -k xcodebuild -version | tr -d "\n" | cut -c 7`.chomp
if XCODE_MAJOR_VERSION == '5'
  target_simulator_name = 'iPhone Retina (4-inch)'
else
  target_simulator_name = 'iPhone 5s'
end

args =
      [
            'clean',
            'test',
            '-SYMROOT=build',
            '-derivedDataPath build',
            '-project calabash.xcodeproj',
            '-scheme XCTest',
            "-destination 'platform=iOS Simulator,name=#{target_simulator_name},OS=latest'",
            '-sdk iphonesimulator',
            '-configuration Debug',
            xcpretty_available ? '| xcpretty -tc && exit ${PIPESTATUS[0]}' : ''
      ]

Dir.chdir(working_dir) do

  # It is possible that this is causing problems on Travis CI on the first run.
  # (>_>) Get up get down Apple XCTest is a joke in my town.
  unless travis_ci?
    RunLoop::SimControl.terminate_all_sims
  end

  cmd = "xcrun xcodebuild #{args.join(' ')}"

  tries = travis_ci? ? 3 : 1
  interval = 5

  on_retry = Proc.new do |_, try, elapsed_time, next_interval|
    if elapsed_time && next_interval
      log_fail "XCTest: attempt #{try} failed in '#{elapsed_time}'; will retry in '#{next_interval}'"
      RunLoop::SimControl.terminate_all_sims
    else
      log_fail "XCTest: attempt #{try} failed; will retry in '#{interval}'"
    end
    RunLoop::SimControl.terminate_all_sims
  end

  class XCTestFailedError < StandardError

  end

  retriable_version = RunLoop::Version.new(Retriable::VERSION)

  if retriable_version >= RunLoop::Version.new('2.0.0')
    options =
          {
                :intervals => Array.new(tries, interval),
                :on_retry => on_retry
          }
  else
    options =
          {
                :tries => tries,
                :interval => interval,
                :on_retry => on_retry
          }
  end

  Retriable.retriable(options) do
    exit_code = do_system(cmd,
                          {:pass_msg => 'XCTests passed',
                           :fail_msg => 'XCTests failed',
                           :exit_on_nonzero_status => false})
    # Not sure if '65' is a magic number that will _always_ indicate that tests
    # have failed.  If we exited non-zero and the exit code does not indicate
    # tests have failed, we assume XCTest failed to launch the simulator. What
    # are you going to do?
    if exit_code != 0 && exit_code != 65
      log_fail "XCTest exited '#{exit_code}' because it could not launch the simulator; will retry."
      raise XCTestFailedError, 'XCTest failed.'
    else
      exit(exit_code)
    end
  end
end
