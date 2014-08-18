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
	scripts/make-calabash-lib-iphonesimulator.rb
	scripts/make-calabash-lib-iphoneos.rb
	scripts/make-calabash-lib-version.rb
	scripts/make-libraries.rb verify-framework

frank:
	rm -rf build
	rm -rf libFrankCalabash.a
	scripts/make-frank-lib-iphonesimulator.rb
	scripts/make-frank-lib-iphoneos.rb
	scripts/make-libraries.rb verify-frank
