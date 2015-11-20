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

Before do |scenario|
  launcher = Calabash::Launcher.launcher
  options = {
    # Add launch options here.
    :uia_strategy => :preferences
  }

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
    launcher.calabash_notify(self)
  end
end

After do |scenario|
  @no_relaunch = false

  # Calabash can shutdown the app cleanly by calling the app life cycle methods
  # in the UIApplicationDelegate.  This is really nice for CI environments, but
  # not so good for local development.
  #
  # See the documentation for NO_STOP for a nice debugging workflow
  #
  # http://calabashapi.xamarin.com/ios/file.ENVIRONMENT_VARIABLES.html#label-NO_STOP
  # http://calabashapi.xamarin.com/ios/Calabash/Cucumber/Core.html#console_attach-instance_method
  unless launcher.calabash_no_stop?
    calabash_exit
  end
end

