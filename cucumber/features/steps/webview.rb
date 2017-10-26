
And(/^the web page has loaded$/) do
  if RunLoop::Environment.xtc?
    timeout = 240
  elsif RunLoop::Environment.ci?
    timeout = 60
  else
    timeout = 30
  end

  message = "Timed out waiting for page to load after #{timeout} seconds"
  options = {
    timeout_message: message,
    timeout: timeout
  }

  wait_for(options) do
    result = query("UIWebView", :isLoading)
    !result.empty? && result.first.to_i == 0
  end
end

Then(/^I can query the webview by accessibility id$/) do
  expect(query("* marked:'landing page'")[0]).to be_truthy
end

Then(/^I can query the webview by accessibility label$/) do
  expect(query("* marked:'Landing page'")[0]).to be_truthy
end

