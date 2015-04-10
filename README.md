| master  | develop | [versioning](VERSIONING.md) | [license](LICENSE) | [contributing](CONTRIBUTING.md)|
|---------|---------|-----------------------------|--------------------|--------------------------------|
|[![Build Status](https://travis-ci.org/calabash/calabash-ios-server.svg?branch=master)](https://travis-ci.org/calabash/calabash-ios-server)| [![Build Status](https://travis-ci.org/calabash/calabash-ios-server.svg?branch=develop)](https://travis-ci.org/calabash/calabash-ios-server)| [![Version](https://img.shields.io/badge/version-0.14.0-green.svg)](https://img.shields.io/badge/version-0.14.0-green.svg) |[![License](https://img.shields.io/badge/licence-Eclipse-blue.svg)](http://opensource.org/licenses/EPL-1.0) | [![Contributing](https://img.shields.io/badge/contrib-gitflow-orange.svg)](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow/)|


## The Calabash iOS Server

http://calaba.sh

The companion of the calabash-ios gem:  https://github.com/calabash/calabash-ios

### Building the Framework


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
