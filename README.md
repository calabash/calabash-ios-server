## The Calabash iOS Server

http://calaba.sh

The companion of the calabash-ios gem:  https://github.com/calabash/calabash-ios

### Building the Framework

```
$ make
```

or from the calabash-ios/calabash-cucumber directory:

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
