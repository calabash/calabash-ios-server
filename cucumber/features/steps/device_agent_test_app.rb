module DeviceAgent
  module Shared

    def wait_for_app
      ["Touch", "Pan", "Rotate/Pinch", "Misc", "Tao"].each do |mark|
        wait_for_element_exists("* marked:'#{mark}'")
      end

      RunLoop.log_debug("Waiting for app to start responding to touches")

      start = Time.now

      timeout = 30
      message = %Q[Waited #{timeout} second for the app to start responding to touches.]
      query = "* marked:'That was touching.'"
      touch_count = 0
      wait_for({timeout: timeout, timeout_message: message}) do
        touch("* marked:'gesture performed'")
        touch_count = touch_count + 1
        !query(query).empty?
        sleep(0.4)
      end

      RunLoop.log_debug("Waited #{Time.now - start} seconds for the app to respond to touches")
      RunLoop.log_debug("Performed #{touch_count} touches while waiting")
    end

    def touch_tab(tabname)
      # Dismiss the keyboard if it is showing
      if keyboard_visible?
        if ipad?
          dismiss_ipad_keyboard
        else
          touch("* marked:'Done'")
        end

        wait_for_none_animating
      end

      touch("* marked:'#{tabname}'")
      wait_for_none_animating

      # Get back to the root view controller of the tab.
      if tabname == "Pan" || tabname == "Misc"
        touch("* marked:'#{tabname}'")
        wait_for_none_animating
      end

      mark = "#{tabname.downcase} page"
      wait_for_element_exists("* marked:'#{mark}'")
    end
  end
end

World(DeviceAgent::Shared)

Given(/^the TestApp has launched$/) do
  wait_for_app
  rotate_home_button_to(:down)
end

Given(/^I am looking at the (Touch|Pan|Rotate\/Pinch|Misc|Tao) tab$/) do |tabname|
  touch_tab(tabname)
end

Given(/^I am looking at the Text Input page$/) do
  touch("* marked:'text input row'")
  wait_for_element_exists("* marked:'Misc Menu'")
  wait_for_none_animating
end

Given(/^I am looking at the Company table$/) do
  touch("* marked:'table row'")
  wait_for_none_animating
  wait_for_element_exists("* marked:'table page'")
end

Given(/^I am looking at the (UIWebView|WKWebView|SafariWebController) page$/) do |name|
  @webview_class = name
  if name == "UIWebView"
    mark = "uiwebview row"
  elsif name == "WKWebView"
    mark = "wkwebview row"
  else
    mark = "safari web controller row"
  end

  touch("* marked:'#{mark}'")
  wait_for_none_animating

  if @webview_class == "SafariWebController"
    wait_for do
      !device_agent.query({marked: "H1 Header!"}).empty?
    end
    wait_for_none_animating
    if xamarin_test_cloud?
      sleep(20.0)
    else
      sleep(2.0)
    end
  else
    wait_for_element_exists("* xpath:'//h1'")
  end
end

When(/^I use the LPServer to clear text$/) do
  # documentation step
end

And(/^there is no visible keyboard on the Text Input page$/) do
  wait_for_no_keyboard
end

Then(/^an error is raised about clear text requiring a first responder$/) do
  expect do
    clear_text_in_first_responder
  end.to raise_error(RuntimeError,
                     /Cannot clear text because no view is first responder/)
end

Then(/^I clear text with the LPServer in the UITextField$/) do
  touch("* marked:'text field'")
  wait_for_keyboard
  keyboard_enter_text("abc")
  query("* marked:'text delegate'", {setText:""})
  clear_text_in_first_responder
  text = query("* marked:'text field'", :text).first
  expect(text).to be == ""

  text = query("* marked:'text delegate'", :text).first
  expected = "textField:shouldChangeCharactersInRange:replacementString:"
  expect(text).to be == expected

  text = query("* marked:'key input'", :text).first
  expected = "TextField: GET /clearText generated notification"
  expect(text).to be == expected

  touch("* marked:'clear key input button'")
  tap_keyboard_action_key
end

Then(/^I clear text with the LPServer in the UITextView$/) do
  touch("* marked:'text view'")
  wait_for_keyboard
  keyboard_enter_text("abc")
  query("* marked:'text delegate'", {setText:""})
  clear_text_in_first_responder
  text = query("* marked:'text view'", :text).first
  expect(text).to be == ""

  text = query("* marked:'text delegate'", :text).first
  expected = "textViewDidChange:"
  expect(text).to be == expected

  text = query("* marked:'key input'", :text).first
  expected = "TextView: GET /clearText generated notification"
  expect(text).to be == expected

  touch("* marked:'dismiss text view keyboard'")
  wait_for_no_keyboard
  touch("* marked:'clear key input button'")
end

Then(/^I clear text with the LPServer in the UIKeyInput view$/) do
  touch("* marked:'key input'")
  wait_for_keyboard
  keyboard_enter_text("abc")
  clear_text_in_first_responder
  text = query("* marked:'key input'", :text).first
  expect(text).to be == ""

  touch("* marked:'dismiss key input keyboard'")
  wait_for_no_keyboard
end

Then(/^I clear text with the LPServer in the UISearchBar$/) do

  query("UITableView", :clearSearchBarDelegateMethodCalls)

  touch("* marked:'Search'")
  wait_for_keyboard
  keyboard_enter_text("abc")
  actual = query("UISearchBar").first["text"]
  expect(actual).to be == "abc"

  clear_text_in_first_responder

  actual = query("UISearchBar").first["text"]
  expect(actual).to be == ""

  json = query("UITableView", :JSONSearchBarDelegateMethodCalls).first
  calls = JSON.parse(json).reverse

  last_call = calls[0]
  expect(last_call[0]).to be == "searchBar:textDidChange:"
  expect(last_call[1][1]).to be == ""

  penultimate_call = calls[1]
  expect(penultimate_call[0]).to be == "searchBar:shouldChangeTextInRange:replacementText:"
  expect(penultimate_call[1][1]).to be == "{0, 0}"
  expect(penultimate_call[1][2]).to be == ""

  touch("* marked:'Cancel'")
end


And(/^I scroll down to the login portion of the web page$/) do
  start = Calabash::Cucumber::Automator::Coordinates.bottom_point_for_full_screen_pan
  finish = Calabash::Cucumber::Automator::Coordinates.top_point_for_full_screen_pan

  if @webview_class == "SafariWebController"
    start[:y] = start[:y] - 60
    finish[:y] = 80
  end

  pan_coordinates(start, finish)

  if @webview_class == "SafariWebController"
    expect(device_agent.query({marked: "First name:"}).count).to be == 1
  else
    expect(query("* css:'input#firstname'").count).to be == 1
  end
  wait_for_none_animating
  sleep(2.0)
end

Then(/^I clear text with the DeviceAgent in a Safari Web Controller$/) do
  device_agent.touch({type: "TextField", index: 0})
  wait_for do
    device_agent.keyboard_visible?
  end

  device_agent.enter_text("abc")

  actual = device_agent.query({type: "TextField", index: 0}).first["value"]
  expect(actual).to be == "abc"

  device_agent.clear_text

  actual = device_agent.query({type: "TextField", index: 0}).first["value"]
  expect(actual).to be == nil

  if ipad?
    dismiss_ipad_keyboard
  else
    device_agent.touch({marked: "Done"})
  end

  wait_for do
    !device_agent.keyboard_visible?
  end

  start = Calabash::Cucumber::Automator::Coordinates.left_point_for_full_screen_pan
  finish = Calabash::Cucumber::Automator::Coordinates.right_point_for_full_screen_pan

  pan_coordinates(start, finish)
  wait_for_none_animating

  sleep(0.5)

  pan_coordinates(start, finish)
  wait_for_none_animating
end


Then(/^I clear text with the LPServer in the web view text input field$/) do
  touch("* css:'input#firstname'")
  wait_for_keyboard
  keyboard_enter_text("abc")

  js = "document.getElementById('firstname').value"
  text = query(@webview_class, {calabashStringByEvaluatingJavaScript: js}).first
  expect(text).to be == "abc"

  sleep(0.5)

  if ipad?
    dismiss_ipad_keyboard
  else
    touch("* marked:'Done'")
  end

  wait_for_no_keyboard

  clear_text("* css:'input#firstname'")
  text = query(@webview_class, {calabashStringByEvaluatingJavaScript: js}).first
  expect(text).to be == ""

  touch("* marked:'Misc Menu'")
  wait_for_none_animating
end


