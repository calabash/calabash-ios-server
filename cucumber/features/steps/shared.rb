module LPTestTarget
  module Cucumber
    def log_app_crashed
      puts "\033[36m   App crashed.\033[0m"
    end

    def get_http_route(path)
      body = http({:method => "GET", :path => path}, {})
      response_body_to_hash(body)
    end
  end
end

World(LPTestTarget::Cucumber)

Then(/^I do something that causes the app to crash$/) do
  begin
    # Use this pattern as example to reproduce crashing
  rescue Errno::ECONNREFUSED => _
    log_app_crashed
    @app_crashed = true
  end
end

Then(/^the app crashes$/) do
  expect(@app_crashed).to be == true
end

Given(/^the app has launched$/) do
  wait_for do
    !query("*").empty?
  end
end

