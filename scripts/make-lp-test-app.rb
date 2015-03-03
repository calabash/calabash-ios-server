#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'test-helpers'))
require 'run_loop'
require 'fileutils'

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))


xcpretty_available = `gem list xcpretty -i`.chomp == 'true'

unless xcpretty_available
  install_gem('xcpretty')
end


env = {

      'ARCHS' => 'i386 x86_64',
      'VALID_ARCHS' => 'i386 x86_64',
      'ONLY_ACTIVE_ARCH' => 'NO'
}

args =
      [
            '-SYMROOT=build',
            '-derivedDataPath build',
            '-project calabash.xcodeproj',
            '-scheme LPTestTarget',
            '-sdk iphonesimulator',
            '-configuration Debug',
            '| xcpretty -c && exit ${PIPESTATUS[0]}'
      ]

Dir.chdir(working_dir) do


  cmd = "xcrun xcodebuild clean build #{args.join(' ')}"

  exit_code = do_system(cmd,
                        {:pass_msg => 'LPTestTarget built',
                         :fail_msg => 'LPTestTarget was not built',
                         :env_vars => env})


  unless exit_code == 0
    log_fail "Could not build LPTestTarget - exit code '#{exit_code}'"
    exit exit_code
  end

  FileUtils.rm_rf(File.join(working_dir, 'LPTestTarget.app'))
  abp = File.join(working_dir, 'build', 'Build', 'Products', 'Debug-iphonesimulator', 'LPTestTarget.app')
  FileUtils.cp_r(abp, working_dir)
  log_info("export APP=#{working_dir}/LPTestTarget.app")
  exit(exit_code)
end
