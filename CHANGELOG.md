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

