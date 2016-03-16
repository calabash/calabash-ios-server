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

And(/^I go to the second tab$/) do
  wait_for do
    !query("UITabBarButton").empty?
  end

  touch("UITabBarButton index:1")
  wait_for_none_animating
end

And(/^I go to the first tab$/) do
  wait_for do
    !query("UITabBarButton").empty?
  end

  touch("UITabBarButton index:0")
  wait_for_none_animating
end

Then(/^touching the (top|middle|bottom) (left|middle|right) button changes the title$/) do |y_id, x_id|
  mark = "#{y_id} #{x_id}"
  qstr = "view marked:'#{mark}'"
  timeout = 8
  message = "Timed out waiting after #{timeout} seconds for #{qstr}"
  options = {
    :timeout => timeout,
    :timeout_message => message
  }

  wait_for(options) do
    !query(qstr).empty?
  end

  title = query(qstr, {:titleForState => 0}).first
  expect(title).to be == "Hidden"

  touch(qstr)

  expected = "Found me!"
  message = "Timed out waiting after #{timeout} seconds for title to change to '#{expected}'"
  options[:timeout_message] = message

  wait_for(options) do
    query(qstr, {:titleForState => 0}).first == expected
  end
end

