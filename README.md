| master  | develop | [versioning](VERSIONING.md) | [license](LICENSE) | [contributing](CONTRIBUTING.md)|
|---------|---------|-----------------------------|--------------------|--------------------------------|
|[![Build Status](https://travis-ci.org/calabash/calabash-ios-server.svg?branch=master)](https://travis-ci.org/calabash/calabash-ios-server)| [![Build Status](https://travis-ci.org/calabash/calabash-ios-server.svg?branch=develop)](https://travis-ci.org/calabash/calabash-ios-server)| [![Version](https://img.shields.io/badge/version-0.18.2-green.svg)](https://img.shields.io/badge/version-0.18.2-green.svg) |[![License](https://img.shields.io/badge/licence-Eclipse-blue.svg)](http://opensource.org/licenses/EPL-1.0) | [![Contributing](https://img.shields.io/badge/contrib-gitflow-orange.svg)](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow/)|

## The Calabash iOS Server

http://calaba.sh

The companion of the calabash-ios gem:  https://github.com/calabash/calabash-ios

### Building

Requires Xcode 6 or Xcode 7.

Xcode 6.4 is actively tested. Older versions of Xcode 6 are not.

Requires ruby >= 2.0.  The latest ruby release is preferred.

```
$ git clone --recursive git@github.com:calabash/calabash-ios-server.git
$ cd calabash-ios-server
$ bundle
```

To build with an alternative Xcode:

```
$ DEVELOPER_DIR=/Xcode/7.1b5/Xcode-beta.app make < rule >
```

If you have build errors, see the xcpretty section below.

Maintainers must install the calabash/calabash-resign private repo.
Details are below.

### Building the Framework

```
make framework
```

### Building the frank plugin

```
$ make frank
```

### Building the dylibs

Requires Xcode 6 or greater.

```
make dylibs
```

**NOTE**

If you are a maintainer, you _must_ install the codesign tool
if you are planning on making a Calabash iOS gem release.

* https://github.com/calabash/calabash-codesign

### Building to embed in Calabash gem

See the calabash-ios/calabash-cucumber/Rakefile for more details.

```
$ cd path/to/calabash-ios/calabash-cucumber
$ be rake build\_server
```

### Testing

```
# Objective-C Unit tests.
$ make xct

# Building libraries.
$ make all

# Integration tests
$ make framework
$ make app-cal
$ cd cucumber
$ bundle update
$ bundle exec cucumber
```

If you are running the XCTests from Xcode, you might see failures in
`LPJSONUtilsTest`.  If you do, clean (Shift + Option + Command + K)
and rerun.

If you want to test the LPTestTarget on device and are having problems
in Xcode or the command line with messages like this:

```
iPhone Developer: ambiguous matches
```

then you must either:

1. `$ CODE_SIGN_IDENTITY="< cert name >" make ipa-cal` (preferred)
2. Update the Xcode project with a specific Code Signing entity.  **DO
   NOT CHECK THESE CHANGES INTO GIT.**

Maintainers should be using the Calabash.keychain
(calabash/calabash-codesign).

### Contributing

* The Calabash iOS Toolchain uses git-flow.
* Contributors should not bump the version.
* See the [CONTRIBUTING.md](CONTRIBUTING.md) guide.
* There is a style guide: [STYLE\_GUIDE.md](STYLE\_GUIDE.md).
* Pull-requests with unit tests will be merged faster.
* Pull-requests with Cucumber integration tests will be merged even faster.

### Releasing

See the [CONTRIBUTING.md](CONTRIBUTING.md) document for instructions.

### xcpretty

https://github.com/supermarin/xcpretty

We use xcpretty to make builds faster and to reduce the amount of
logging.  Travis CI, for example, has a limit on the number of lines of
logging that can be generated; xcodebuild breaks this limit.

The only problem with xcpretty is that it does not report build errors
very well.  If you encounter an issue with any of the make rules, run
without xcpretty:

```
$ XCPRETTY=0 make ipa
```

### Licenses

Calabash iOS Server uses several third-party sources.  You can find the
licenses for these sources in the third-party-licenses directory.

