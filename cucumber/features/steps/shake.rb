
When(/^I shake the device for (\d+) seconds?$/) do |seconds|
  result = shake(seconds.to_i)
  expect(result["duration"]).to be == seconds.to_i
end

