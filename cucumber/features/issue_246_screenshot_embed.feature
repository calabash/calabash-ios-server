@screenshot
@issue_246
Feature:  Screenshot embed in and out of cucumber world

# undefined method `embed` (NoMethodError) when calling screenshot_and_raise
# https://github.com/calabash/calabash-ios/issues/246

Scenario: screenshots outside of a page
When I use screenshot_and_raise in the context of cucumber
Then I should get a runtime error

Scenario: screenshots in a page that does not extend IBase
When I screenshot_and_raise in a page that does not inherit from IBase
Then I should get a runtime error
But it should not be a NoMethod error for embed

Scenario: screenshots in a page that does extend IBase
When I screenshot_and_raise in a page that does inherit from IBase
Then I should get a runtime error
But it should not be a NoMethod error for embed

