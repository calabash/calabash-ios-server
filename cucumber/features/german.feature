@localization
@simulator
Feature: Can launch a simulator in German

@german
Scenario: Launch simulator in German and query for text
Given the app has launched
And I go to the second tab
Then I see localized text "Zweite View"

