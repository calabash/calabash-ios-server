all:
	$(MAKE) framework
	$(MAKE) frank
	$(MAKE) dylibs

clean:
	rm -rf build
	rm -rf calabash.framework
	rm -rf libFrankCalabash.a
	rm -rf calabash-dylibs

framework:
	rm -rf build
	rm -rf calabash.framework
	scripts/make-calabash-lib.rb sim
	scripts/make-calabash-lib.rb device
	scripts/make-calabash-lib.rb version
	scripts/make-libraries.rb verify-framework

frank:
	rm -rf build
	rm -rf libFrankCalabash.a
	scripts/make-frank-lib.rb sim
	scripts/make-frank-lib.rb device
	scripts/make-libraries.rb verify-frank

dylibs:
	rm -rf build
	rm -rf calabash-dylibs
	scripts/make-calabash-dylib.rb sim
	scripts/make-calabash-dylib.rb device
	CERT_CHECKSUM=337976ad9ace375ac06cd8fea2edb0c7276dec2a72d005ca5559a8bbf09c8841 \
								scripts/make-libraries.rb verify-dylibs

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

version-tool:
	rm -rf version
	scripts/make-version.sh
	version --revision ALL
