DOCUMENTATION COMING
--------------------


## master branch contains the 0.10.x line. 
This is intended to be integrated into the Frank project, although unfortunately for various reasons I've not been able to work on this recently. It should build however.

## the calabash-ios-server branch is the 0.9.x line
This is Calabash as is currently used. The easiest way to build is to checkout calabash-ios-server and calabash-ios
(client) and look at the Rakefile inside calabash-ios/calabash-cucumber. Alternatively just build from xcode.

Contributing to the 0.9.x line
--------------------

##### make a new feature branch on the 0.9.x line
1. make a fork
2. check out the calabash-ios-server branch (`git checkout calabash-ios-server`)
3. resolve submodule revisions (`git submodule update --init --recursive`)
4. remove any untracked directories (like `lib`) (`rm -rf lib`)
5. create your feature branch (`git checkout -b my-new-feature`)

##### building the server
6. clone/fork the calabash-ios repo (`git clone git://github.com/calabash/calabash-ios.git`)
7. `cd calabash-ios/calabash-cucumber/`
8. build the server with rake (`rake build_server`)

##### make your changes and test
9. make some changes
10. build the server (step 3 above)
11. install the framework and test
12. rinse and repeat 

##### make the pull request
13. push to the branch (`git push -u origin my-new-feature`)
14. create new pull request

