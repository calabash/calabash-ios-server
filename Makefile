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
	bin/make/dylibs.sh 337976ad9ace375ac06cd8fea2edb0c7276dec2a72d005ca5559a8bbf09c8841

install_test_binaries:
	$(MAKE) framework
	$(MAKE) dylibs
	./scripts/install-test-binaries.rb

webquery_headers:
	scripts/insert-js-into-webquery-headers.rb

test_app:
	scripts/make-lp-test-app.rb

xct:
	scripts/test/xctest.rb

# For developers only.  This script is not part of the library
# build process.
version:
	bin/make/version.sh

