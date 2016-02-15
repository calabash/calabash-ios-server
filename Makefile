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
	bin/make/dylibs.sh 7bcdf1e95ae393eadfca69b607a19077fcf1f5625fcbd5f3d0d182eb0cd5ed36

webquery_headers:
	bundle exec bin/make/insert-js-into-webquery-headers.rb

xct:
	$(MAKE) xctests

xctests:
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

