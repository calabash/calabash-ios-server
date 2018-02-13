
Then(/^the server identifier is from the embedded binary$/) do
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
    expected = server_id.split("=")[1]
    actual = server_version["server_identifier"]
    expect(actual).to be == expected
end

Then(/^the server identifier is from the embedded dylib$/) do
  expected = "c1ae656317ac5a2707a0de9a361ad1049c34edf0"
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
