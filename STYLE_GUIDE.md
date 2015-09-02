### Objective-C

1. Use spaces, not tabs.
2. Indents should be 2 spaces.
3. As much as possible, limit each line to no more than 80 characters.
4. Use Unicode UTF-8 and Unix newlines.

When in doubt, refer to this guide:

* https://github.com/raywenderlich/objective-c-style-guide

If you are making a change to file, limit the number of style changes to as close to zero as possible so the diff can be easily read.

One strategy is to make your changes, submit the PR, have it accepted, then make a style commit onto develop.

### ARC

The server uses Objective-C ARC and retain-release memory management.  We are slowly converting to ARC.  When you touch a file, evaluate its suitability for converting to ARC.  This is a tricky business and is very easy to get wrong.  If you have any doubts, don't convert to ARC.  All new files should be written with ARC.  You must do two things:

```
# 1. Add this warning to the top of the file
#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

# 2. Add the -fobjc-arc flag to the file in all the targets.
```

### Xcode

Make sure your Xcode Text Editing settings match what you see in the screenshots below.

===

![2015-06-11_16-53-35](https://cloud.githubusercontent.com/assets/466104/8110104/c816d50e-105a-11e5-949e-96752e3e5b1f.png)

===

![2015-06-11_16-53-44](https://cloud.githubusercontent.com/assets/466104/8110117/e887b5e2-105a-11e5-81dc-5b7bf0e5dc26.png)
