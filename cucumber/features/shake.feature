@quarantine
@shake
Feature: Shake

@alert
Scenario: Shake the device
  Given the app has launched
  When I shake the device for 1 second
  Then I see the shake detected alert
  And I dismiss the alert by tapping the OK button

