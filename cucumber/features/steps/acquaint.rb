
And(/^I am running on an iPhone 6 Plus device$/) do
  expect(server_version["form_factor"]).to be == "iphone 6+"
end

And(/^I search for my acquaintance "([^"]*)"$/) do |name|
  tokens = name.split(" ")
  search_for = tokens.reverse.join(", ")

  query_str = "* marked:'#{search_for}'"

  visible = lambda do
    query(query_str).count == 1
  end

  counter = 0
  loop do
    break if visible.call || counter == 4
    scroll("tableView", :down)
    sleep(0.4)
    counter = counter + 1
  end

  if !visible.call
    fail(%Q[Scrolled down #{counter} times but did not see

#{query_str}
])
  end

  @acquaintance_query = query_str
end

Then(/^I can see her details$/) do
  touch(@acquaintance_query)
  wait_for_none_animating

  qstr = "* marked:'mgreen@calcomlogistics.com'"
  timeout = 1
  message = %Q[Timed out after #{timeout} seconds waiting for

  #{qstr}

]

  options = {
    :timeout => timeout,
    :timeout_message => message
  }

  wait_for_element_exists(qstr, options)
end

And(/^I go back to my list of acquaintances$/) do
  touch("* marked:'List'")
  wait_for_none_animating
end

And(/^I can do the same thing by touching the details disclosure$/) do
  touch("#{@acquaintance_query} parent view:'AcquaintanceCell' descendant button")
  wait_for_none_animating
end

Then(/^I can reveal the easter egg$/) do
  qstr = "* marked:'easter egg'"
  timeout = 10
  message = %Q[Timed out after #{timeout} seconds waiting for

  #{qstr}

]

  options = {
    :timeout => timeout,
    :timeout_message => message
  }

  wait_for_element_exists(qstr, options)

  touch(qstr)

  qstr = "* {text CONTAINS 'You found me!'}"
  timeout = 10
  message = %Q[Timed out after #{timeout} seconds waiting for

  #{qstr}

]

  wait_for_element_exists(qstr, options)
end

And(/^then I can dismiss the easter egg$/) do
  sleep(0.4)
  touch("* marked:'OK'")
end

