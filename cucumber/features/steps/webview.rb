
And(/^the web page has loaded$/) do
  wait_for do
    result = query("UIWebView", :isLoading).first
    result == 0
  end
end

Then(/^I can query the webview by accessibility id$/) do
  expect(query("* marked:'landing page'")[0]).to be_truthy
end

Then(/^I can query the webview by accessibility label$/) do
  expect(query("* marked:'Landing page'")[0]).to be_truthy
end

