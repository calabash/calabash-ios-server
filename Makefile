all:
	$(MAKE) framework
	$(MAKE) dylibs

clean:
	rm -rf build
	rm -rf Products
	rm -rf calabash.framework
	rm -rf calabash-dylibs

framework:
	bin/make/framework.sh

dylibs:
	# The argument is the sha of the cert used to resign the dylib.
	# $ cd ~/.calabash/calabash-codesign
	# $ sha256 apple/certs/calabash-developer.p12
	bin/make/dylibs.sh 4d5868ea6f8778abaf31b56703ebd8d2f45dfb0aabaf767fa9cbd85203f395c1

webquery_headers:
	bundle exec bin/make/insert-js-into-webquery-headers.rb

unit-tests:
	$(MAKE) xctests

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

