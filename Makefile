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
	bin/make/make-framework.sh

frank:
	bin/make/make-frank-plugin.sh

dylibs:
	rm -rf build
	rm -rf calabash-dylibs
	scripts/make-calabash-dylib.rb sim
	scripts/make-calabash-dylib.rb device
	CERT_CHECKSUM=337976ad9ace375ac06cd8fea2edb0c7276dec2a72d005ca5559a8bbf09c8841 \
								scripts/make-libraries.rb verify-dylibs
	xcrun codesign --display --verbose=4 calabash-dylibs/libCalabashDyn.dylib

dylib_sim:
	rm -rf build
	rm -rf calabash-dylibs
	scripts/make-calabash-dylib.rb sim
	scripts/make-libraries.rb verify-sim-dylib

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

version:
	scripts/make-version.sh
	bin/version --revision ALL
