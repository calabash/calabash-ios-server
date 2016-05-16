#!/usr/bin/env ruby

require "run_loop"
require "retriable"
require "luffa"

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

use_xcpretty = ENV["XCPRETTY"] != "0"

xcode = RunLoop::Xcode.new

default_sim_name = RunLoop::Core.default_simulator
default_sim = RunLoop::Device.device_with_identifier(default_sim_name)

core_sim = RunLoop::CoreSimulator.new(default_sim, nil, {:xcode => xcode})
core_sim.launch_simulator

sim_udid = default_sim.udid

xcode = RunLoop::Xcode.new

if xcode.version_gte_7?
  warnings_as_errors="GCC_TREAT_WARNINGS_AS_ERRORS=YES"
else
  warnings_as_errors="GCC_TREAT_WARNINGS_AS_ERRORS=NO"
end

args =
      [
            'test',
            '-SYMROOT=build',
            '-derivedDataPath build/xctest',
            '-project calabash.xcodeproj',
            '-scheme XCTest',
            "-destination id=#{sim_udid}",
            '-sdk iphonesimulator',
            '-configuration Debug',
            warnings_as_errors,
            use_xcpretty ? '| xcpretty -tc --report junit && exit ${PIPESTATUS[0]}' : ''
      ]

Dir.chdir(working_dir) do

  cmd = "xcrun xcodebuild #{args.join(' ')}"

  tries = Luffa::Environment.travis_ci? ? 3 : 1
  interval = 5

  on_retry = Proc.new do |_, try, elapsed_time, next_interval|
    Luffa.log_fail "XCTest: attempt #{try} failed in '#{elapsed_time}'; will retry in '#{next_interval}'"
    RunLoop::CoreSimulator.quit_simulator
    core_sim.launch_simulator
  end

  class XCTestFailedError < StandardError

  end

  options =
  {
      :intervals => Array.new(tries, interval),
      :on_retry => on_retry,
      :on => [XCTestFailedError]
  }

  env = { "COMMAND_LINE_BUILD" => "1" }

  Retriable.retriable(options) do
    exit_code = Luffa.unix_command(cmd,
                                   {:pass_msg => 'XCTests passed',
                                    :fail_msg => 'XCTests failed',
                                    :env_vars => env,
                                    :exit_on_nonzero_status => false})
    if Luffa::Environment.travis_ci?
      if exit_code != 0
        Luffa.log_fail "XCTest exited '#{exit_code}' - did a test fail or did the tests not start?"
        raise XCTestFailedError, 'XCTest failed.'
      end
    else
      exit(exit_code)
    end
  end
end

