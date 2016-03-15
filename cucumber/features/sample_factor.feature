@sample_factor
Feature: sample_factor for non-optimized apps and zoomed mode

@wip
Scenario: Touch a small button
Given the app has launched
And I go to the second tab
And I touch the secret button
Then the secret button title changes to Found me
