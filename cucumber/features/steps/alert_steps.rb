
def alert_exists?(alert_title=nil)
  if alert_title.nil?
    res = uia('uia.alert() != null')
  else
    if ios6?
      res = uia("uia.alert().staticTexts()['#{alert_title}'].label()")
    else
      res = uia("uia.alert().name() == '#{alert_title}'")
    end
  end

  if res['status'] == 'success'
    res['value']
  else
    false
  end
end

def wait_for_alert
  timeout = 4
  message = "Waited #{timeout} seconds for an alert to appear"
  options = {timeout: timeout, timeout_message: message}

  wait_for(options) do
    alert_exists?
  end
end

def alert_view_query_str
  if ios8? || ios9?
    "view:'_UIAlertControllerView'"
  elsif ios7?
    "view:'_UIModalItemAlertContentView'"
  else
    'UIAlertView'
  end
end

def alert_button_views
  wait_for_alert

  if ios8? || ios9?
    query = "view:'_UIAlertControllerActionView'"
  elsif ios7?
    query = "view:'_UIModalItemAlertContentView' descendant UITableView descendant label"
  else
    query = 'UIAlertView descendant button'
  end
  query(query)
end

def alert_button_titles
  alert_button_views.map { |res| res['label'] }.compact
end

def all_alert_labels
  wait_for_alert
  query = "#{alert_view_query_str} descendant label"
  query(query)
end

def non_alert_button_views
  button_titles = alert_button_titles()
  all_labels = all_alert_labels()
  all_labels.select do |res|
    !button_titles.include?(res['label']) &&
          res['label'] != nil
  end
end

def alert_message
  with_max_y = non_alert_button_views.max_by do |res|
    res['rect']['y']
  end

  with_max_y['label']
end

Then(/^I (should )?see the "([^"]*)" alert$/) do |_should, message|
  wait_for_alert
  expect(alert_message).to be == message
end
