module CalSmokeApp
  module ScreenshotEmbed

    def screenshot_count
      screenshot_dir = ENV["SCREENSHOT_PATH"]
      if !screenshot_dir
        screenshot_dir = "./screenshots"
      end

      unless File.exist?(screenshot_dir)
        FileUtils.mkdir_p(screenshot_dir)
      end

      Dir.glob("#{screenshot_dir}/*.png").count
    end

    def log_screenshot_context(kontext, e)
      $stdout.puts "  #{kontext} #{e.class} #{e.message}"
      $stdout.flush
    end

    def expect_screenshot_count(expected)
      if Calabash::Cucumber::Environment.xtc?
        # Skip this test on the XTC.
      else
        expect(screenshot_count).to be == expected
      end
    end
  end
end

World(CalSmokeApp::ScreenshotEmbed)

When(/^I use screenshot_and_raise in the context of cucumber$/) do
  last_count = screenshot_count

  begin
    screenshot_and_raise 'Hey!'
  rescue => e
    @screenshot_and_raise_error = e
    log_screenshot_context("Cucumber", e)
    expect_screenshot_count(last_count + 1)
  end
end

When(/I screenshot_and_raise in a page that does not inherit from IBase$/) do
  last_count = screenshot_count

  begin
    NotPOM::HomePage.new.my_buggy_method
  rescue => e
    log_screenshot_context("NotPOM", e)
    @screenshot_and_raise_error = e
    expect_screenshot_count(last_count + 1)
  end
end

When(/I screenshot_and_raise in a page that does inherit from IBase$/) do
  last_count = screenshot_count

  begin
    POM::HomePage.new(self).my_buggy_method
  rescue => e
    log_screenshot_context("POM", e)
    @screenshot_and_raise_error = e
    expect_screenshot_count(last_count + 1)
  end
end

Then(/^I should get a runtime error$/) do
  if @screenshot_and_raise_error.nil?
    raise 'Expected the previous step to raise an error'
  end

  expect(@screenshot_and_raise_error).to be_a_kind_of(RuntimeError)
end

But(/^it should not be a NoMethod error for embed$/) do
  expect(@screenshot_and_raise_error.message[/embed/, 0]).to be_falsey
  expect(@screenshot_and_raise_error).not_to be_a_kind_of(NoMethodError)
end

