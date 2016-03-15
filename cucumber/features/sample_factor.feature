@sample_factor
Feature: sample_factor for non-optimized apps and zoomed mode

The server must be able to detect two Scenarios:

1. When the device is in Zoomed vs. Standard mode
2. When the application is not optimized for the iPhone 6* screen sizes.

In the first case, the sample factor does not change.  In the second case, the
sample factor must change.

The LPTestTarget is _optimized_ for the larger screen sizes; it has the correct
launch images, the correct app icons, and image assets in @3x sizes.  This
Scenario tests that the scale factor is correct in Zoomed and Standard view
modes.  There is a 2x2 point button that, when touched, changes its title from
"Hidden" to "Found me!".

There are six tests to run:

1. Target an iPhone 6 simulator
2. Target an iPhone 6 Plus simulator
3. Target an iPhone 6 in Zoomed mode
4. Target an iPhone 6 in Standard mode
5. Target an iPhone 6 Plus in Zoomed mode
6. Target an iPhone 6 Plus in Standard mode

To change the display mode, use Settings.app:

Display & Brightness > Display Zoom > Standard | Zoomed > Set

On iOS Simulators, there is no Zoomed or Standard mode.

Scenario: Touch a small button
Given the app has launched
And I go to the second tab
And I touch the secret button
Then the secret button title changes to Found me

