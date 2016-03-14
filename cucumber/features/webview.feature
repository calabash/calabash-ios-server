@webview
Feature: Interacting with WebViews

Scenario: Query WebView by accessibility attributes
Given the app has launched
And I go to the first tab
And the web page has loaded
Then I can query the webview by accessibility id
And I can query the webview by accessibility label

