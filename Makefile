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
	bin/make/dylibs.sh

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

