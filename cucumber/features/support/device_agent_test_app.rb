
module TestApp
  require "calabash-cucumber"
  require "run_loop"

  def self.app
    app = File.expand_path(File.join("device-agent-test-app",
                                     "TestApp.app"))
    RunLoop::App.new(app)
  end

  def self.ipa
    app = File.expand_path(File.join("device-agent-test-app",
                                     "TestApp.ipa"))
    RunLoop::Ipa.new(app)
  end

  def self.options
    xcode = RunLoop::Xcode.new
    simctl = RunLoop::Simctl.new
    instruments = RunLoop::Instruments.new
    device = RunLoop::Device.detect_device({}, xcode, simctl, instruments)

    if device.simulator?
      app = TestApp.app
    else
      app = TestApp.ipa.bundle_identifier
    end
    {
      :app => app,
      :device => device
    }
  end
end

