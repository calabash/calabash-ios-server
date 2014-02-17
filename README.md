## The Calabash iOS Server

http://calaba.sh

The companion of the calabash-ios gem:  https://github.com/calabash/calabash-ios

### the master branch is the 0.9.x line

This is Calabash as is currently used.  The easiest way to build is to checkout calabash-ios-server and calabash-ios (client) and look at the Rakefile inside calabash-ios/calabash-cucumber.  Alternatively just build from xcode.

### frank branch contains the 0.10.x line

This is intended to be integrated into the Frank project.

### Contributing to the 0.9.x line

```
## make a new feature branch on the 0.9.x line
 1. make a fork
 2. check out the master branch        => $ git checkout master
 3. resolve submodule revisions        => $ git submodule update --init --recursive
 4. remove any untracked directories 
 5. create your feature branch         => $ git checkout -b my-new-feature

## building the server
 6. clone/fork the calabash-ios repo   => $ git clone git://github.com/calabash/calabash-ios.git
 7. in your local calabash-ios repo    => $ cd calabash-ios/calabash-cucumber
 8. build the server with rake         => $ rake build_server

## make your changes and test
 9. make some changes
10. build the server (step 6 above)
11. install the framework and test
12. rinse and repeat 

##  make the pull request
13. push to the branch                 => $ git push -u origin my-new-feature
14. create new pull request
```
