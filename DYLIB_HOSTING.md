### libCalabashFAT.dylib

The Calabash CI machine hosts files that contain information about the latest successful build of the Calabash dylib - including a download URL.  The files are in 3 formats:  JSON, YAML, and plain text.

There are dylibs for the latest successful build of develop and master.

Here is an example URL that points information about the latest successful build of the develop branch.

http://calabash-ci.macminicolo.net:8080/job/Calabash%20iOS%20Server%20develop/lastSuccessfulBuild/artifact/Products/s3/s3.json

If you want the master branch, change `develop` to `master`.

Here are examples of the three formats.

```
# YAML
branch: HEAD                                            
git_sha: 8b368a8ffedd8280f508b75f55a86ee0676294f1       
dylib_url: http://calabash-ci.macminicolo.net:8080/job/Calabash%20iOS%20Server%20PR/lastSuccessfulBuild/artifact/Products/s3/libCalabashFAT.dylib                                                                                 
headers_zip_url: http://calabash-ci.macminicolo.net:8080/job/Calabash%20iOS%20Server%20PR/lastSuccessfulBuild/artifact/Products/s3/Headers.zip                                                                                    
date: 2017-06-02T08:18:28+0200 
```

```
# JSON
{
  "branch" : "HEAD",
  "git_sha" : "8b368a8ffedd8280f508b75f55a86ee0676294f1",
  "dylib_url" : "http://calabash-ci.macminicolo.net:8080/job/Calabash%20iOS%20Server%20PR/lastSuccessfulBuild/artifact/Products/s3/libCalabashFAT.dylib",
  "headers_zip_url" : "http://calabash-ci.macminicolo.net:8080/job/Calabash%20iOS%20Server%20PR/lastSuccessfulBuild/artifact/Products/s3/Headers.zip",
  "date" : "2017-06-02T08:18:28+0200"
}
```

```
# txt
http://calabash-ci.macminicolo.net:8080/job/Calabash%20iOS%20Server%20PR/lastSuccessfulBuild/artifact/Products/s3/libCalabashFAT.dylib
```
