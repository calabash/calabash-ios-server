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

