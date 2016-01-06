all:
	$(MAKE) framework
	$(MAKE) frank
	$(MAKE) dylibs

clean:
	rm -rf build
	rm -rf Products
	rm -rf calabash.framework
	rm -rf libFrankCalabash.a
	rm -rf calabash-dylibs

framework:
	bin/make/framework.sh

frank:
	bin/make/frank-plugin.sh

dylibs:
	# The argument is the sha of the developer.p12 used to resign the dylib.
	# See https://github.com/calabash/calabash-codesign for details.
	bin/make/dylibs.sh 9e7be7fd966ed49fab7f0335e148421ca05165a804928529dda17e1031ab5a4a

webquery_header:
	bundle exec bin/make/insert-js-into-webquery-header.rb

xct:
	bundle exec bin/test/xctest.rb

# Makes the LPTestTarget.app without Calabash linked.
# This target is suitable for testing dylib injection.
app:
	bin/make/app.sh

# Makes the LPTestTarget with Calabash linked.
app-cal:
	bin/make/app-cal.sh

# Make the LPTestTarget with Calabash linked
ipa-cal:
	bin/make/ipa-cal.sh

# For developers only.  This script is not part of the library
# build process.
version:
	bin/make/version.sh

