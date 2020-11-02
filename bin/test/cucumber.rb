#!/usr/bin/env ruby

require "fileutils"
require "tmpdir"
require "bundler"
require "luffa"

cucumber_args = "#{ARGV.join(" ")}"

server_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
calabash_framework = File.join(server_dir, 'calabash.framework')

# If calabash.framework was built by a previous step, use it.
unless File.exist?(calabash_framework)
  Dir.chdir server_dir do
    if !system("make", "framework")
      raise "There was an error while running 'make framework'"
    end
  end
end

app = File.join(server_dir, "Products", "test-target", "app-cal", "LPTestTarget.app")

unless File.exist?(app)
  Dir.chdir server_dir do
    if !system("make", "app-cal")
      raise "There was an error while running 'make app-cal'"
    end
  end
end

working_dir = File.join(server_dir, "cucumber")

Dir.chdir working_dir do
  Bundler.with_clean_env do

    FileUtils.rm_rf("reports")
    FileUtils.mkdir_p("reports")

    if !system("bundle", "update")
      raise "There was an error while running 'bundle update'"
    end

    require "run_loop"

    xcode = RunLoop::Xcode.new
    xcode_version = xcode.version
    sim_version = xcode.ios_version

    if RunLoop::Environment.azurepipelines?
      # we have to add iPhone 12* devices when we'll be working on adding support for Xcode version that support them
      devices = {
        :iphone11 => 'iPhone 11',
        :iphone11Pro => 'iPhone 11 Pro',
        :iphone11ProMax => 'iPhone 11 Pro Max',
        :iPadPro97 => 'iPad Pro (9.7-inch)',
        :iPhone8 => 'iPhone 8',
        :iPhone8Plus => 'iPhone 8 Plus'
      }
    else
      devices = {
        :iphoneXs => 'iPhone Xs',
        :iphoneXsMax => 'iPhone Xs Max'
      }
    end

    if !system("bundle", "exec", "run-loop", "simctl", "manage-processes")
      raise "There was an error while running 'bundle exec run-loop simctl manage-processes'"
    end

    simulators = RunLoop::Simctl.new.simulators

    env_vars = {}

    passed_sims = []
    failed_sims = []
    devices.each do |key, name|
      match = simulators.find do |sim|
        sim.name == name && sim.version == sim_version
      end

      if !match
        raise "Could not find a match for simulator with name #{name} and version #{sim_version}"
      end

      if system({"DEVICE_TARGET" => match.udid},
          "bundle", "exec", "cucumber",
           "-p", "simulator",
           "-f", "json", "-o", "reports/cucumber.json",
           "-f", "junit", "-o", "reports/junit",
           "--tags", "~@device",
           "--tags", "~@device_only",
           "--tags", "~@xtc",
           "--tags", "~@xtc_only")

        passed_sims << name
      else
        failed_sims << name
      end

      if !system("bundle", "exec", "run-loop", "simctl", "manage-processes")
        raise "There was an error while running 'bundle exec run-loop simctl manage-processes'"
      end

      sleep(5.0)
    end

    Luffa.log_info '=== SUMMARY ==='
    Luffa.log_info ''
    Luffa.log_info 'PASSING SIMULATORS'
    passed_sims.each { |sim| Luffa.log_info(sim) }
    Luffa.log_info ''
    Luffa.log_info 'FAILING SIMULATORS'
    failed_sims.each { |sim| Luffa.log_info(sim) }

    sims = devices.count
    passed = passed_sims.count
    failed = failed_sims.count

    puts ''
    Luffa.log_info "passed on '#{passed}' out of '#{sims}'"

    # if none failed then we have success
    exit 0 if failed == 0

    exit failed unless RunLoop::Environment.azurepipelines?

    # we'll take 75% passing as good indicator of health
    expected = 75
    actual = ((passed.to_f/sims.to_f) * 100).to_i

    if actual >= expected
      Luffa.log_info "##vso[task.logissue type=warning;]We failed '#{failed}' sims, but passed '#{actual}%' so we say good enough"
      Luffa.log_info "##vso[task.complete result=SucceededWithIssues;]Cucumber test run warning"
      exit 0
    else
      Luffa.log_info "##vso[task.logissue type=error;]We failed '#{failed}' sims, which is '#{actual}%' and not enough to pass"
      exit 1
    end
  end
end

