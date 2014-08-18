all:
	$(MAKE) framework
	$(MAKE) frank
clean:
	rm -rf build
	rm -rf calabash.framework
	rm -rf libFrankCalabash.a

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
	scripts/make-frank-lib-iphonesimulator.rb
	scripts/make-frank-lib-iphoneos.rb
	scripts/make-libraries.rb verify-frank
