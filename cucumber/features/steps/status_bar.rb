module LPTestTarget
  module StatusBar
    require "calabash-cucumber/connection_helpers"

    def status_bar
       result = http({:method => :get,
											:raw => true,
											:path => "statusBar"})
			 hash = JSON.parse(result)

       expect(hash["outcome"]).to be == "SUCCESS"

			 hash["results"]
    end
  end
end

World(LPTestTarget::StatusBar)

Then(/^I can ask for status bar information$/) do
  rotate_home_button_to(:down)
  bar = status_bar

  expect(bar["orientation"]).to be == "down"
  expect(bar["hidden"]).to be == false

  frame = bar["frame"]
  expect(frame["x"]).to be == 0
  expect(frame.has_key?("y")).to be_truthy
  expect(frame.has_key?("width")).to be_truthy
  expect(frame.has_key?("height")).to be_truthy
end

