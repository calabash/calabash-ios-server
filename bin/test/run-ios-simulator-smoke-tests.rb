#!/usr/bin/env ruby

require "luffa"
require "run_loop"
require "fileutils"
require "tmpdir"

cucumber_args = "#{ARGV.join(' ')}"

server_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
calabash_framework = File.join(server_dir, 'calabash.framework')

# If calabash.framework was built by a previous step, use it.
unless File.exist?(calabash_framework)
  Dir.chdir server_dir do
    Luffa.unix_command('make framework')
  end
end

working_dir = Dir.mktmpdir

Dir.chdir working_dir do

  Luffa.unix_command('git clone --depth 1 --branch develop --recursive https://github.com/calabash/calabash-ios')
  Luffa.unix_command('git clone --depth 1 --recursive https://github.com/calabash/ios-smoke-test-app.git')
  Luffa.unix_command("git clone --depth 1 --recursive https://github.com/calabash/run_loop")

end

calabash_gem_dir = File.join(working_dir, 'calabash-ios')
run_loop_gem_dir = File.join(working_dir, "run_loop")
smoke_test_working_dir = File.join(working_dir, "ios-smoke-test-app", "CalSmokeApp")

Luffa.unix_command("rm -rf #{smoke_test_working_dir}/calabash.framework")
Luffa.unix_command("ditto #{calabash_framework} #{smoke_test_working_dir}/calabash.framework")

Bundler.with_clean_env do
  Dir.chdir smoke_test_working_dir do

    Luffa.unix_command('rm -rf Gemfile*')
    Luffa.unix_command('rm -rf .bundle')

    other_gems = File.join("config", "xtc-other-gems.rb")

    File.open('Gemfile', 'w') do |file|
      file.write("source 'https://rubygems.org'\n")
      file.write("gem 'run_loop', :path => \"#{run_loop_gem_dir}\"\n")
      file.write("gem 'calabash-cucumber', :path => \"#{calabash_gem_dir}\"\n")
      File.readlines(other_gems).each do |line|
        file.write(line)
      end
    end

    Luffa.unix_command("bundle install",
                       {:pass_msg => 'bundled',
                        :fail_msg => 'could not bundle'})

    Luffa.unix_command('make app-cal',
                       {:pass_msg => 'built app',
                        :fail_msg => 'could not build app'})

    xcode = RunLoop::Xcode.new
    xcode_version = xcode.version
    sim_major = xcode_version.major + 2
    sim_minor = xcode_version.minor

    sim_version = RunLoop::Version.new("#{sim_major}.#{sim_minor}")

    devices = {
      :air => 'iPad Air',
      :iphone4s => 'iPhone 4s',
      :iphone5s => 'iPhone 5s',
      :iphone6 => 'iPhone 6',
      :iphone6plus => 'iPhone 6 Plus'
    }

    simulators = RunLoop::SimControl.new.simulators

    env_vars = {}

    passed_sims = []
    failed_sims = []
    devices.each do |key, name|
      cucumber_cmd = "bundle exec cucumber -p simulator #{cucumber_args}"

      match = simulators.find do |sim|
        sim.name == name && sim.version == sim_version
      end

      env_vars = {'DEVICE_TARGET' => match.udid}

      exit_code = Luffa.unix_command(cucumber_cmd, {:exit_on_nonzero_status => false,
                                                    :env_vars => env_vars})
      if exit_code == 0
        passed_sims << name
      else
        failed_sims << name
      end
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

    # the travis ci environment is not stable enough to have all tests passing
    exit failed unless Luffa::Environment.travis_ci?

    # we'll take 75% passing as good indicator of health
    expected = 75
    actual = ((passed.to_f/sims.to_f) * 100).to_i

    if actual >= expected
      Luffa.log_pass "We failed '#{failed}' sims, but passed '#{actual}%' so we say good enough"
      exit 0
    else
      Luffa.log_fail "We failed '#{failed}' sims, which is '#{actual}%' and not enough to pass"
      exit 1
    end
  end
end

