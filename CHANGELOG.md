### 0.21.4

* Static initializer can skip loading the embedded LPServer #410

### 0.21.3

No source code changes.

We need to release a patch of Test Cloud Agent nuget, because 0.21.2 was
not released correctly (built from incorrect tag).

### 0.21.2

* Jenkins: jobs push calabash artifacts to S3 #406
* Test: force xcpretty to write build/reports/junit.xml #404
* Find touch coords for 768x1014 Web Apps displayed on iPad Pro form
  factors #403
* Support legacy apps displayed on iPhone X in letter box #402
* LPDevice: fix iPad Pro and iPad model to form-factor map #401
* LPDevice: update iPhone 8, 8+, and 10 model numbers #400
* LPDevice: add iPhone X, 8, 8+ model numbers #399
* Enable tests to dispatch blocks and wait for their results on the main
  dispatch queue #393 @Lievesley

### 0.21.1

Advancing the version to create a tag from which we can distribute
libraries built with Xcode 9 GM.

### 0.21.0

* Update build scripts for Xcode 9 #395
* Server: namespace LPQUResources to avoid conflict with Xcode/LinkPresention.framework #394

### 0.20.7

* Update for Xcode 9 #391
* Fix iPad Pro 10.5 touch coordinates for non-optimized apps #390
* LPDevice: add new iPad models for June 2017 #389
* Can specify suiteName when making changes to user preferences endpoint #386

### 0.20.6

* Prepare for Jenkins to stage artifacts to S3 #383
* GET /clearText: call delegate methods and post notifications after
  removing text from first responder #382
* Jenkins: force Xcode 7 CoreSimulatorService to load #380
* Fix: subviewWithMark only returns a match if the last subview has the mark #379
* Update shasum of the cert used to sign the calabash dylibs #376

### 0.20.4

* Log POST requests with body #372

### 0.20.3

* Update form factor table with latest iphone 7 device model info #370

### 0.20.2

* scrollToMark: a generic operation for scrolling to a mark in any
  UIScrollView #368
* Scroll to marked operations should descend to depth N #367 @JoeSSS

### 0.20.1

This release contains no server changes.  The version has been bumped to keep
Xamarin.TestCloud.Agent and calabash-cucumber gem versions in sync.

### 0.20.0

* Update for Xcode 8 GM and iPhone 7/7+ #364
* Update CLI build scripts for Xcode 8 #363
* Server: implement statusBar route #362
* Server: add set device orientation route #361

### 0.19.2

* LPDevice: fix sampleFactor for legacy apps in zoomed mode on iphone 6+ #360
* Detect legacy apps and used the scaleFactor for iPhone 6 Plus devices #358

### 0.19.1

This release _really_ removes support form "marked" as a free text
matcher on WebViews.

Also, the rect:x and rect:y JSON returned by queries on WebViews
now (correctly) indicate the top left corner of the element.
Previously, rect:x and rect:y referred to the _center_.  This is
breaking change.  After a long discussion, we decided that this is
a long standing _bug_ rather than a change in the API; an API change
would require a non-patch release.

* Remove special :marked handling from WebView queries - take 2 #355
* WebQuery: rect x and y should indicate the top-left corner of the
  element #354
* Increment LPTestTarget CFBundleVersion for every build #352
* LPScreenshot: handle exceptions when calling snapshot API #351
* Scenarios for testing Cucumber embed #350
* Response: set the content type to application/json #349
* Cucumber: bump version to 2.0 #347
* LPDevice: detecting 6se and iPad Pro 9in #346

### 0.19.0

This release removes support for "marked" as a free text matcher on
WebViews. See this issue for details:

https://github.com/calabash/calabash-ios/issues/735

* Update Objective-C test stack #343
* LPVersionRoute: remove reference to calabash\_version #342
* LPDevice: fix ip address reporting #340
* Fix touch coordinates for Zoomed display mode and apps that are not
  optimized for iPhone 6 screen sizes #339
* LPJSONUtils: set max and min float to avoid JSON parse errors #338
* Remove special :marked handling from WebView queries #337

### 0.18.2

Thanks @MortenGregersen and @kaorijp for testing #334

* Screenshot: use drawViewHierarchy when possible #334
* Bonjour: create a unique service instance name #332

### 0.18.1

This release has no new features.

* Stabilize tests for Xcode 7.3 beta 3

### 0.18.0

This release expands support for interacting with iFrames using the css
selector: `query("webView css:'iframe' css:'h1'")`.

* LPTestTarget: replace Storyboard with XIBs #328
* LPTestTarget: resign embedded dylibs #327
* Add DE localization to LPTestTarget #326
* Expand iFrame support using css:'iframe' queries #308

### 0.17.1

This is a patch release which fixes scroll on UIWebView and WKWebView.

* Fix LPScrollOperation for WebView #321
* Travis: add slack notifications #318
* Make: update the cert fingerprint for dylib signing #317
* Fix JavaScript insertion into LPSetTextOperation.h #312
* Fix JavaScript insertion into LPWebQuery.h #310
* Update LPTestTarget build scripts for Xcode 7.2 #309
* Cucumber: add @shake feature to quarantine #307
* Version tool: turn off legacy coverage build option #306 @kaorijp
* Update build scripts for Xcode 7.2 #305

### 0.17.0

* Libs: should not generate code coverage files #296
* Version tool is emitting profiling info #295
* ARM builds are forced to emit bitcode #294
* Standup Jenkins: take 2 #293
* LPDevice: add missing iPadPro identifier #291
* LPShakeRoute needs to respond to POST and include :results key in JSON
  response #288
* LPSuspendAppRoute returns correct keys in response #287
* Travis CI should build the dylibs and submit a Test Cloud job #286
* Cucumbers for expanded backdoor capabilities #284
* Fix and/or update build system for Xcode 7.1 #282 @stopiccot
* Add 'shake' route to programmatically shake device #280 @tommeier
* Replace deprecated methods in LPQueryLog route #275
* Replace NSLog calls with LPLog\* calls #273
* LPInvoker handles __self__ and __nil__ tokens in arguments #270
* Reflection route #269
* Improve the LPProcessInfoRoute #268
* Fix :preferences strategy for iOS 9 #267
* Server logs IP address at launch #265 @Oddj0b
* Add 'suspend' route to suspend and resume app #261
* Expand backdoor route to handle arbitrary method signatures #220
  @sapieneptus

### 0.16.4

* New build system for libraries: responding Xcode 7.0.1 bitcode changes #256

## 0.16.2

* Detect and identify Xcode 7 simulators #242

### 0.16.0 and 0.16.1

These releases contains no code-level changes.  They have been
made so we can tag and distribute libraries that have been compiled
with Xcode 7.  This is necessary because of the new bit code
settings in Xcode 7.

### 0.15.0

* LPQueryAllOperation needs some TLC #204
* Convert many project files to ARC
* Xcode 7: remove prefix header from libraries #227
* Xcode 7: resolve new warnings #225
* New route to lookup the current keyboard's l10n #221 @svevang
* Backdoor route should return a 'results' key #219
* Update CocoaHTTPServer 2.3 #216
* Expand the features of LPInvoker
* Version tool can return git revision #201
* Fixup memory leak in LPConditionRoute #193
* Updates GCDAsyncSocket to 7.4.1
* Adds CocoaLumberjack logging via LPCocoaLumberjack
* MapKit categories were part of no target #180 @nalbion
* When checking for no animation, ignore animations with trivially short
  durations #142 @JoeSzymanski
* LPIntrospectionRoute: a server route for object introspection #178

### 0.14.3

* Avoid [NSURL fileSystemRepresentation] on iOS 6 #175
* LPDevice: use 'unknown' for unknown form-factors #174
* Version route: add key for CFBundleShortVersionString #173

### 0.14.2

* LPJSONUtils fix double quoting of strings in jsonifyObject: #171
* CalabashServer: log dlopen UIAutomation errors #170
* Use 'CalSmoke' text in test scripts #169
* Date picker: send actions for all UIControlEvents #168
* Don't include non-public LPHTTPServer.h in CalabashServer.h #166 @ldiqual
* LPJSONSerializer can encode arbitrary objects #165
* Set GCC\_TREAT\_WARNINGS\_AS\_ERRORS=YES for command-line builds #164
* Replace UIView+LPIsWebView category with LPIsWebView static class #163
* More guards in [LPJSONUtils jsonifyAccessibilityElement:] against unrecognized selectors # 16
* LPSliderOperation should support any UIControlEvent the target slider is registered to receive #157
* Try/Catch around LPInvoker invokeSelector:withTarget: #156
* Put UISliderOperation under ARC

### 0.14.1

* Guard calls to lpIsWebView since we also query non-UIView objects #152
* Fix fall-through causing double write of http chunk #151
* Fix case where a coordinate is inf or nan #150

### 0.14.0

* Handle case where DOCUMENT\_NODE has empty rect #148
* add setText: support for WKWebView #146
* fix setText: support for UIWebView #146
* Create WKWebView ObjC category at runtime #145
* can report iphone6 form factors #141
* can load dylib plug-ins #140

### 0.13.0

* Migrate objc code from calabash-js submodule #123
* Scroll gestures don't scroll past content size #120 @idcuesta
* Fix an edge-case crash in dump route #119

### 0.12.3

* Add app target to xctest bundle #111
* Fix memory leak in LPVersionRoute a0d565b
* Replace jsonifyView: with dictionaryByEncodingView: #113 - fixes UISlider crash

