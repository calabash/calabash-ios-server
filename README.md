| master  | develop | [versioning](VERSIONING.md) | [license](LICENSE) | [contributing](CONTRIBUTING.md)|
|---------|---------|-----------------------------|--------------------|--------------------------------|
|[![Build Status](https://travis-ci.org/calabash/calabash-ios-server.svg?branch=master)](https://travis-ci.org/calabash/calabash-ios-server)| [![Build Status](https://travis-ci.org/calabash/calabash-ios-server.svg?branch=develop)](https://travis-ci.org/calabash/calabash-ios-server)| [![Version](https://img.shields.io/badge/version-0.15.0-green.svg)](https://img.shields.io/badge/version-0.15.0-green.svg) |[![License](https://img.shields.io/badge/licence-Eclipse-blue.svg)](http://opensource.org/licenses/EPL-1.0) | [![Contributing](https://img.shields.io/badge/contrib-gitflow-orange.svg)](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow/)|

## The Calabash iOS Server

http://calaba.sh

The companion of the calabash-ios gem:  https://github.com/calabash/calabash-ios

### Building the Framework

Requires Xcode 6 or Xcode 7.

Xcode 6.4 is actively tested.  Older versions of Xcode 6 are not.

```
$ git clone --recursive git@github.com:calabash/calabash-ios-server.git
$ cd calabash-ios-server
$ make framework
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

# Integration tests.
$ scripts/test/run
```

If you are running the XCTests from Xcode, you might see failures in
`LPJSONUtilsTest`.  If you do, clean (Shift + Option + Command + K)
and rerun.

### Contributing

* The Calabash iOS Toolchain uses git-flow.
* Contributors should not bump the version.
* See the [CONTRIBUTING.md](CONTRIBUTING.md) guide.
* There is a style guide: [STYLE\_GUIDE.md](STYLE\_GUIDE.md).
* Pull-requests with unit tests will be merged faster.

### Releasing

See the [CONTRIBUTING.md](CONTRIBUTING.md) document for instructions.

### Licenses

Calabash iOS Server uses several third-party sources.  You can find the
licenses for these sources in the third-party-licenses directory.

