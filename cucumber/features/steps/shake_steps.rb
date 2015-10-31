
When(/^I shake the device$/) do
  http({:method => :get, :path => 'shake'})
end
