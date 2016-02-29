@background
Feature: Send App to Background
In order to test how my app behaves when it goes to the background
As a developer
I want a Background API

Background: Launch the app
  Given the app has launched

Scenario: Simulate touching the home button
  Then backgrounding the app for less than one second raises an error
  And I can send the app to the background for 1 second
  And I can send the app to the background for 10 seconds
  And I can send the app to the background for a long time
  Then I go to the second tab
  And I go to the first tab

