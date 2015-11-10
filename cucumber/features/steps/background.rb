module LPTestTarget
  module Background
    def application_state
      get_http_route("suspend")["results"]
    end
  end
end

World(LPTestTarget::Background)

Then(/^backgrounding the app for less than one second raises an error$/) do
  expect do
    send_app_to_background(0.5)
  end.to raise_error ArgumentError
end

And(/^I can send the app to the background for (\d+) seconds?$/) do |seconds|


  send_app_to_background(seconds.to_i)
  start = Time.now

  sleep 1.0

  wait_for({timeout: seconds.to_i + 5.0}) do
    application_state == "active"
  end

  elapsed = Time.now - start - 1.0
  RunLoop.log_debug("Total time in background: #{elapsed}")
end

And(/^I can send the app to the background for a long time/) do
  if RunLoop::Environment.xtc?
    seconds = 61
    wait_time = seconds + 10
  else
    seconds = 15
    wait_time = seconds + 5
  end

  send_app_to_background(seconds)
  start = Time.now

  sleep 1.0

  wait_for({timeout: wait_time}) do
    application_state == "active"
  end

  elapsed = Time.now - start - 1.0
  RunLoop.log_debug("Total time in background: #{elapsed}")
end

