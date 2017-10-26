
Then(/^I can call a backdoor with dispatch_after$/) do
  expect(backdoor("backdoorWithDispatchAfter")).to be == true
end
