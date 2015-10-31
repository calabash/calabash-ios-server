@shake
Feature: Shake

@alert
Scenario: Mimic shake on device
  Given the app has launched
  When I shake the device
  Then I should see the "shake detected!" alert

