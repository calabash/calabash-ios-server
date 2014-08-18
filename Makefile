all:
	$(MAKE) framework
	$(MAKE) frank
	$(MAKE) dylib
clean:
	rm -rf build
	rm -rf calabash.framework
	rm -rf libFrankCalabash.a
	rm -rf libCalabash.dylib

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

dylib:
	rm -rf build
	rm -rf libCalabash.dylib
	scripts/make-calabash-dylib.rb sim
	scripts/make-calabash-dylib.rb device
	scripts/make-libraries.rb verify-dylib
