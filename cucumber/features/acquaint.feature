@acquaint
Feature: Acquaint app on iPhone 6 Plus

The Acquaint app is an example of a legacy app that has absolutely no support
for iPhone 6 and 6 Plus form factors.

We have an example app: https://github.com/calabash/ios-iphone-only-app that
has some support for iPhone 6 and 6 Plus form factors.

The Acquaint app uses the iPhone 4" (iPhone 5, 5c, 5s, and 6se) coordinate space
on iPhone 6 Plus form factors and not the expected sampled coordinate space that
is used in the iPhoneOnly app.

Will run without configuration on iPhone 6 Plus simulator using:

$ be cucumber -t @acquaint

The LPServer dylib will be made before the test run and injected into the running
application after it launches.  This is the best way to debug the coordinates.

To target a physical device, the acquaint/AcquaintNativeIOS.ipa must be
installed on the device.  The command line args will be something like this:

$ APP=acquaint/AcquaintNativeiOS.ipa \
  DEVICE_ENDPOINT=http://denis.local:37265 \
  DEVICE_TARGET=denis be cucumber -t @acquaint

The LPServer dylib will be loaded at runtime - it is embedded in the .ipa
application bundle.

To submit a test to the Xamarin Test Cloud, do the following:

$ XTC_API_TOKEN=<> XTC_ACCOUNT=<> xtc-submit-acquaint.rb
$ xtc-submit-acquaint.rb <api token> <account> [device set]

This test is only expected to run and pass on a iPhone 6+.

Then AcquaintNativeiOS app was modified in the follow ways:

1. ShowTouchesWindow was added to visually inspect touches.
2. The TestCloudAgent is no longer linked.
3. The LPServer is loaded at runtime when targeting physical devices.
4. A 2x2 button was added to the details view.  When touched it reveals
   a UIAlertView.

The changes can be seen here:

https://github.com/jmoody/app-acquaint/tree/feature/prepare-app-for-calabash-testing

Scenario: Touch coordinates are correct
Given the app has launched
And I am running on an iPhone 6 Plus device
Then I search for my acquaintance "Monica Green"
Then I can see her details
And I go back to my list of acquaintances
And I can do the same thing by touching the details disclosure
Then I can reveal the easter egg
And then I can dismiss the easter egg

