[![Build Status](https://travis-ci.org/calabash/calabash-ios-server.svg?branch=master)](https://travis-ci.org/calabash/calabash-ios-server)
 [![License](https://go-shields.herokuapp.com/license-Eclipse-blue.png)](http://opensource.org/licenses/EPL-1.0)

## The Calabash iOS Server

http://calaba.sh

The companion of the calabash-ios gem:  https://github.com/calabash/calabash-ios

### Building the Framework

```
$ make
```

### Building the frank plugin

```
$ make frank
```

### Building the dylibs

```
make dylibs
```

Dylibs support is based on this article:

http://ddeville.me/2014/04/dynamic-linking/

### Building to embed in Calabash gem

From the calabash-ios/calabash-cucumber directory:

```
# see the calabash-ios/calabash-cucumber/Rakefile for details
$ rake build_server
```

### testing

```
# test building the framework
$ cd scripts
$ ./make-framework.rb
```
