
module Acquaint
  require "calabash-cucumber"
  require "run_loop"

  def self.iphone6plus_sim
    simctl = Calabash::Cucumber::Environment.simctl
    sims = simctl.simulators

    candidates = sims.select do |sim|
      sim.name[/iPhone 6 Plus/]
    end

    sorted = candidates.sort_by { |sim| sim.version.to_s }.reverse

    iphone6plus = sorted[0]

    if iphone6plus.nil?
      raise "Could not find an iPhone 6 Plus simulator"
      $stderr.flush
    end
    iphone6plus
  end

  def self.app
    app = File.expand_path(File.join("acquaint", "AcquaintNativeiOS.app"))
    RunLoop::App.new(app)
  end

  def self.ipa
    app = File.expand_path(File.join("acquaint", "AcquaintNativeiOS.ipa"))
    RunLoop::Ipa.new(app)
  end

  def self.dylib
    lib = File.expand_path(File.join("..", "calabash-dylibs", "libCalabashDynSim.dylib"))

    Dir.chdir(File.join("..")) do
      require "bundler"
      Bundler.with_clean_env do
        system("make dylibs")
      end
    end

    if !File.exist?(lib)
      raise "Could not find the calabash dylib to inject into the simulator"
      $stderr.flush
    end
    lib
  end

  def self.sim_options
    if RunLoop::Environment.device_target
      device = RunLoop::Environment.device_target
      inject = nil
      app = Acquaint.ipa.bundle_identifier
    else
      device = Acquaint.iphone6plus_sim
      inject = Acquaint.dylib
      app = Acquaint.app
    end
    {
      :app => app,
      :inject_dylib => inject,
      :device => device
    }
  end
end

