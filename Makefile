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
	scripts/make-libraries.rb verify-dylibs

install_test_binaries:
	$(MAKE) dylibs
	./scripts/install-test-binaries.rb

