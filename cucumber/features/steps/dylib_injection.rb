
module Calabash
  module LPServer

    def lpserver_embedded_version
      path = installed_test_target_app_executable
      lpserver_identifier_from_binary(path)
    end

    def lpserver_dylib_version
      path = installed_test_target_app_cal_dylib
      lpserver_identifier_from_binary(path)
    end

    def lpserver_identifier_from_binary(path)
      strings = RunLoop::Strings.new(path).send(:dump)
      server_id = strings[/LPSERVERID=.+$/]
      server_id.split("=")[1]
    end

    def test_target_app
      file = File.join("..",  "Products", "test-target",
                       "app-cal", "LPTestTarget.app")
      RunLoop::App.new(file)
    end

    def test_target_simulator
      target = ENV["DEVICE_TARGET"] || RunLoop::Core.default_simulator
      RunLoop::Device.device_with_identifier(target)
    end

    def test_target_core_sim
      app = test_target_app
      simulator = test_target_simulator
      RunLoop::CoreSimulator.new(simulator, app)
    end

    def installed_test_target_app
      core_sim = test_target_core_sim
      app_dir = core_sim.send(:installed_app_bundle_dir)
      RunLoop::App.new(app_dir)
    end

    def installed_test_target_app_executable
      app = installed_test_target_app
      File.join(app.path, app.executable_name)
    end

    def installed_test_target_app_cal_dylib
      app = installed_test_target_app
      File.join(app.path, "libCalabashFAT.dylib")
    end
  end
end

World(Calabash::LPServer)

Then(/^the server identifier is from the embedded binary$/) do
  expected = lpserver_embedded_version
  actual = server_version["server_identifier"]
  expect(actual).to be == expected
end

Then(/^the server identifier is from the embedded dylib$/) do
  expected = lpserver_dylib_version
  actual = server_version["server_identifier"]
  expect(actual).to be == expected
end

When(/^running in App Center the entitlement injector is loaded$/) do
  if RunLoop::Environment.xtc?
    mark = "Tomato: promoted to vegetable"
    timeout = 10
    message = "Timed out waiting for #{mark} after #{timeout} seconds"
    options = {timeout: timeout, timeout_message: message}
    wait_for_element_exists("* marked:'#{mark}'", options)
  end
end

When(/^running locally the entitlement injector is not loaded$/) do
  if !RunLoop::Environment.xtc?
    mark = "Tomato: still a fruit"
    timeout = 10
    message = "Timed out waiting for #{mark} after #{timeout} seconds"
    options = {timeout: timeout, timeout_message: message}
    wait_for_element_exists("* marked:'#{mark}'", options)
  end
end
