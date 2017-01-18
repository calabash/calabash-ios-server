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
	# The argument is the sha of the cert used to resign the dylib.
	# $ cd ~/.calabash/calabash-codesign
	# $ sha256 apple/certs/calabash-developer.p12
	bin/make/dylibs.sh cbf0fbb58909be6cdb17d93c4bc089382d84d617815f39a85c70b47280177758

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

