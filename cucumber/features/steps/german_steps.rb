
Then(/^I see localized text "([^"]*)"$/) do |text|
  wait_for do
    !query("* marked:'#{text}'").empty?
  end
end
