
Then(/^backgrounding the app for less than one second raises an error$/) do
  expect do
    send_app_to_background(0.5)
  end.to raise_error ArgumentError
end

And(/^I can send the app to the background for (\d+) seconds?$/) do |seconds|
  send_app_to_background(seconds.to_i)

  sleep(seconds.to_i + 2.0)

  wait_for({:timeout => 2.0}) do
    !query("*").empty?
  end
end

