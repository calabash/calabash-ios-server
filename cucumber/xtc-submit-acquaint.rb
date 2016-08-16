#!/usr/bin/env ruby

require "run_loop"
require "bundler"

# ACQ_* are defined in Jenkins.
XTC_API_TOKEN=ENV["ACQ_XTC_API_TOKEN"] || ENV["XTC_API_TOKEN"] || ARGV[0]
XTC_ACCOUNT=ENV["ACQ_XTC_ACCOUNT"] || ENV["XTC_ACCOUNT"] || ARGV[1]

DEVICE_SET = ARGV[2] || ["0adda5bd", "553e29d2", "b4fbb17e"].sample

WORKING_DIR=File.expand_path("xtc-submit-acquaint")

FileUtils.rm_rf(WORKING_DIR)
FileUtils.mkdir(WORKING_DIR)

FileUtils.cp_r("acquaint/AcquaintNativeIOS.ipa", WORKING_DIR)
FileUtils.cp_r("acquaint/AcquaintNativeIOS.app.dSYM", WORKING_DIR)
FileUtils.cp_r("features", WORKING_DIR)
FileUtils.cp_r("config/xtc-profiles.yml", "#{WORKING_DIR}/cucumber.yml")

GEMFILE=File.join(WORKING_DIR, "Gemfile")
OTHER_GEMS=File.readlines("config/xtc-other-gems")

File.open(GEMFILE, "w") do |file|
  file.puts(%Q[gem "calabash-cucumber"])
  OTHER_GEMS.each do |line|
    file.puts(line)
  end
end

Dir.chdir(WORKING_DIR) do
  Bundler.with_clean_env do

    system("bundle update")

    args = [
       "exec", "test-cloud", "submit",
       "AcquaintNativeiOS.ipa",
       XTC_API_TOKEN,
       "--user", XTC_ACCOUNT,
       "-d", DEVICE_SET,
       "-c", "cucumber.yml",
       "-p", "acquaint",
       "--async",
       "--series", "master",
       "--dsym-file", "AcquaintNativeiOS.app.dSYM"
    ]

    system("bundle", *args)
  end
end

