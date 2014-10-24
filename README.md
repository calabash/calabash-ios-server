[![Build Status](https://travis-ci.org/calabash/calabash-ios-server.svg?branch=master)](https://travis-ci.org/calabash/calabash-ios-server)
 [![License](https://go-shields.herokuapp.com/license-Eclipse-blue.png)](http://opensource.org/licenses/EPL-1.0)

## The Calabash iOS Server

http://calaba.sh

The companion of the calabash-ios gem:  https://github.com/calabash/calabash-ios

### Failing Travis CI builds

**RESOLVED** ~~Travis updated to Xcode 6 and since then our CI has been failing because the instruments process is popping a Finder dialog requesting permission to 'analyze other processes'.  We are working with the Travis team to resolve this issue.~~

Jobs on Travis are flickering because the test apps are crashing on iOS 7.1 Simulators.  We have not been able to reproduce the behavior on Jenkins or locally.

The build queues for Travis are incredibly long:  6 - 8 hours at times.  This is too long for us to wait for feedback on changes.

### Building the Framework

```
$ make framework
```

### Building the frank plugin

```
$ make frank
```

### Building the dylibs

Building the dylibs requires that you inject xcspecs directly into your Xcode.app application bundle.  For instructions, refer to the link below.

You will also need to update the code signing Build Settings of the `calabash-dylib-device` target with your credentials.

```
make dylibs
```

Dylibs support is based on this article:

http://ddeville.me/2014/04/dynamic-linking/

### Building to embed in Calabash gem

See the calabash-ios/calabash-cucumber/Rakefile for more details.

```
$ cd path/to/calabash-ios/calabash-cucumber
$ rake build_server

# If you need to build without the dylibs
$ CALABASH_NO_DYLIBS=1 rake build_server
```

### Testing

* https://travis-ci.org/calabash/calabash-ios-server

```
# make rules
$ scripts/test/test-make-rules.rb

# cucumber tests + make rules
$ scripts/test/run
```
