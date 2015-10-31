@shake
Feature: Shake

@alert
Scenario: Mimic shake on device
  Given the app has launched
  When I shake the device
  Then I see the "shake detected!" alert
  And I dismiss the alert by tapping the OK button

