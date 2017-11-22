require 'calabash-cucumber/launcher'

# You can find examples of more complicated launch hooks in these
# two repositories:
#
# https://github.com/calabash/ios-smoke-test-app/blob/master/CalSmokeApp/features/support/01_launch.rb
# https://github.com/calabash/ios-webview-test-app/blob/master/CalWebViewApp/features/support/01_launch.rb

module Calabash::Launcher
  @@launcher = nil

  def self.launcher
    @@launcher ||= Calabash::Cucumber::Launcher.new
  end

  def self.launcher=(launcher)
    @@launcher = launcher
  end
end

Before("@no_relaunch") do
  @no_relaunch = true
end

Before("@acquaint") do
  if !xamarin_test_cloud?
    @acquaint_options = Acquaint.options
  end
end

Before("@device_agent_test_app") do
  if !xamarin_test_cloud?
    @device_agent_test_app_options = TestApp.options
  end
end

Before("@skip_embedded_server") do
  if !xamarin_test_cloud?
    @relaunch = true
    @skip_embedded_server_options = {}
    file = File.join("..",  "Products", "test-target",
                     "app-cal", "LPTestTarget.app")
    app = RunLoop::App.new(file)
    target = ENV["DEVICE_TARGET"] || RunLoop::Core.default_simulator
    simulator = RunLoop::Device.device_with_identifier(target)

    core_sim = RunLoop::CoreSimulator.new(simulator, app)
    app_dir = core_sim.send(:installed_app_bundle_dir)
    app = RunLoop::App.new(app_dir)
    file = File.join(app.path, app.executable_name)

    strings = RunLoop::Strings.new(file).send(:dump)
    server_id = strings[/LPSERVERID=.+$/]
    if !server_id
      raise %Q[
Could not find LPSERVERID embedded in app calabash.framework not linked
]
      exit 1
    end

    @skip_embedded_server_options[:env] = {
      "XTC_SKIP_LPSERVER_TOKEN" => server_id.split("=")[1],
      "DYLD_INSERT_LIBRARIES" => File.join(app.path, "libCalabashFAT.dylib")
    }

    @skip_embedded_server_options
  end
end

Before("@german") do
  if !xamarin_test_cloud?
    target = ENV["DEVICE_TARGET"] || RunLoop::Core.default_simulator

    simulator = RunLoop::Device.device_with_identifier(target)

    RunLoop::CoreSimulator.erase(simulator)
    RunLoop::CoreSimulator.set_locale(simulator, "de")
    RunLoop::CoreSimulator.set_language(simulator, "de")

    @args = ["-AppleLanguages", "(de)", "-AppleLocale", "de"]
  end
end

Before do |scenario|
  launcher = Calabash::Launcher.launcher

  if @acquaint_options
    options = @acquaint_options
  elsif @device_agent_test_app_options
    options = @device_agent_test_app_options
  elsif @skip_embedded_server_options
    options = @skip_embedded_server_options
  else
    options = {
      # Add launch options here.
      # Stick with defaults; preferences on device is not stable
      # :uia_strategy => :preferences
    }
  end

  if @args
    options[:args] = @args.dup
    @args = nil
  end

  relaunch = true

  if @no_relaunch
    begin
      launcher.ping_app
      attach_options = options.dup
      attach_options[:timeout] = 1
      launcher.attach(attach_options)
      relaunch = launcher.device == nil
    rescue => e
      RunLoop.log_info2("Tag says: don't relaunch, but cannot attach to the app.")
      RunLoop.log_info2("#{e.class}: #{e.message}")
      RunLoop.log_info2("The app probably needs to be launched!")
    end
  end

  if relaunch
    launcher.relaunch(options)
  end
end

After("@german") do
  if !xamarin_test_cloud?
    target = ENV["DEVICE_TARGET"] || RunLoop::Core.default_simulator

    simulator = RunLoop::Device.device_with_identifier(target)

    RunLoop::CoreSimulator.erase(simulator)
    RunLoop::CoreSimulator.set_locale(simulator, "en_US")
    RunLoop::CoreSimulator.set_language(simulator, "en-US")
  end
end

After do |scenario|
  @no_relaunch = false
  @acquaint_options = nil
  @device_agent_test_app_options = nil
  @skip_embedded_server_options = nil
  # Calabash can shutdown the app cleanly by calling the app life cycle methods
  # in the UIApplicationDelegate.  This is really nice for CI environments, but
  # not so good for local development.
  #
  # See the documentation for QUIT_APP_AFTER_SCENARIO for a nice debugging workflow
  #
  # http://calabashapi.xamarin.com/ios/file.ENVIRONMENT_VARIABLES.html#label-QUIT_APP_AFTER_SCENARIO
  # http://calabashapi.xamarin.com/ios/Calabash/Cucumber/Core.html#console_attach-instance_method
  if launcher.quit_app_after_scenario?
    calabash_exit
    sleep 1.0
  end
end

