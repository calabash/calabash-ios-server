@device_agent_test_app
Feature: DeviceAgent TestApp

The Calabash and UITest iOS stacks use several test applications to
document and test their behaviors.  For various reasons, there is no
single test app that has all the views required for testing every
feature of the Calabash and UITest iOS stacks.

The DeviceAgent TestApp happens to contain almost every Text Input
Field required to test the LPServer's ability to trigger delegate
methods and post notifications while clearing test.

@lpserver_clear_text
Scenario: LPServer GET /clearText
Given the TestApp has launched
And I am looking at the Misc tab
And I am looking at the Text Input page
When I use the LPServer to clear text
And there is no visible keyboard on the Text Input page
Then an error is raised about clear text requiring a first responder
Then I clear text with the LPServer in the UITextField
Then I clear text with the LPServer in the UITextView
Then I clear text with the LPServer in the UIKeyInput view
Given I am looking at the Pan tab
And I am looking at the Company table
Then I clear text with the LPServer in the UISearchBar

@webview
@lpserver_set_text
Scenario:  LPServer POST /setText to clear INPUT fields on web views
Given I am looking at the Misc tab
And I am looking at the UIWebView page
And I scroll down to the login portion of the web page
Then I clear text with the LPServer in the web view text input field
Given I am looking at the Misc tab
And I am looking at the WKWebView page
And I scroll down to the login portion of the web page
Then I clear text with the LPServer in the web view text input field

@webview
@safari
@device_agent
Scenario: DeviceAgent clear text in a Safari Web Controller
Given I am looking at the Misc tab
And I am looking at the SafariWebController page
And I scroll down to the login portion of the web page
Then I clear text with the DeviceAgent in a Safari Web Controller
