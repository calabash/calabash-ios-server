#!/usr/bin/env ruby

require "luffa"
require "bundler"

device_set = ENV["XTC_DEVICE_SET"]

if !device_set || device_set == ""
  device_set = ARGV[0]
end

if !device_set || device_set == ""
  device_set = ["1b98f5d9", "99536756", "8c294161", "ab029afc"].sample
end

if !Luffa::Environment.travis_ci? && !Luffa::Environment.jenkins_ci?
  # For submitting tests locally
  Luffa.unix_command("make ipa-cal")
  Dir.chdir("cucumber") do
    Bundler.with_clean_env do
      Luffa.unix_command("bundle update")
      Luffa.unix_command("bundle exec briar xtc #{device_set}")
    end
  end
else

  # Only maintainers can submit XTC tests.
  if Luffa::Environment.travis_ci? && ENV["TRAVIS_SECURE_ENV_VARS"] != "true"
    Luffa.log_info("Skipping XTC submission; non-maintainer activity")
    exit 0
  end

  # Previous Travis steps do:
  # 1. install cucumber/.env
  # 2. make the ipa
  # 3. stage the ipa

  Dir.chdir("cucumber") do
    Bundler.with_clean_env do
      Luffa.unix_command("bundle update")

      require "run_loop"

      # rake install must succeed
      calabash_gem = `bundle show calabash-cucumber`.strip
      ["dylibs", "staticlib"].each do |lib_dir|
        FileUtils.mkdir_p(File.join(calabash_gem, lib_dir))
      end

      ["libCalabashDyn.dylib", "libCalabashDynSim.dylib"].each do |lib|
        source = File.join("..", "calabash-dylibs", lib)
        target = File.join(calabash_gem, "dylibs", lib)
        FileUtils.mv(source, target)
      end

      lib = "libFrankCalabash.a"
      source = File.join("..", lib)
      target = File.join(calabash_gem, "staticlib", lib)
      FileUtils.mv(source, target)

      source = File.join("..", "calabash.framework")
      target = File.join(calabash_gem, "staticlib", "calabash.framework.zip")

      args = ['ditto', '-c', '-k', '--rsrc', '--sequesterRsrc', '--keepParent',
              source, target]
      Luffa::Debug.with_debugging do
        RunLoop::Xcrun.new.exec(args, {log_cmd: true})
      end

      Luffa.unix_command("bundle exec briar xtc #{device_set}")
    end
  end
end

