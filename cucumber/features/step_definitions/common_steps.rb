Given(/^that the app has launched$/) do
  wait_for do
    !query('view').empty?
  end
end

When(/^I take a screenshot, a png is created$/) do
  with_env('SCREENSHOT_PATH', nil) do
    name = 'my_screenshot'
    `rm -f #{name}*.png`
    unless Dir.glob("./#{name}*.png").empty?
      raise "Could not remove screenshot with name '#{name}'"
    end
    path = screenshot(name: name)
    unless File.exist?(path)
      raise "Expected screenshot at '#{path}'"
    end
    `rm -f #{path}`
  end
end
