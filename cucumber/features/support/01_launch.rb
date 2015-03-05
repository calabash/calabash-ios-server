require 'calabash-cucumber/launcher'
require 'singleton'

module Calabash
  class LaunchControl
    include Singleton

    def launcher
      @launcher ||= Calabash::Cucumber::Launcher.new
    end

    def dylib
      @dylib ||= lambda {
        dirname = File.dirname(__FILE__)
        joined = File.join(dirname, '..', '..', '..', 'calabash-dylibs', 'libCalabashDynSim.dylib')
        File.expand_path(joined)
      }.call
    end

  end
end


Before do |scenario|
  options =
        {
              :inject_dylib => Calabash::LaunchControl.instance.dylib
        }

  launcher = Calabash::LaunchControl.instance.launcher
  launcher.relaunch(options)
  launcher.calabash_notify(self)
end

After do |scenario|
  launcher = Calabash::LaunchControl.instance.launcher
  unless launcher.calabash_no_stop?
    calabash_exit
  end
end
