@sample_factor
Feature: sample_factor for non-optimized apps and zoomed mode

The server must be able to detect two Scenarios:

1. When the device is in Zoomed vs. Standard mode
2. When the application is not optimized for the iPhone 6* screen sizes.

In the first case, the sample factor does not change.  In the second case, the
sample factor must change.

The LPTestTarget is _optimized_ for the larger screen sizes; it has the correct
launch images, the correct app icons, and image assets in @3x sizes.  This
Scenario tests that the sample factor is correct in Zoomed and Standard display
modes.  There are a series of 2x2 point buttons that, when touched, change title
from "Hidden" to "Found me!".

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

Scenario: Touch small buttons
Given the app has launched
And I go to the second tab
Then touching the top left button changes the title
Then touching the top middle button changes the title
Then touching the top right button changes the title
Then touching the middle left button changes the title
Then touching the middle right button changes the title
Then touching the bottom left button changes the title
Then touching the bottom middle button changes the title
Then touching the bottom right button changes the title

