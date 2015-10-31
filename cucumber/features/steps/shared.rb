
Given(/^the app has launched$/) do
  wait_for do
    !query("*").empty?
  end
end

