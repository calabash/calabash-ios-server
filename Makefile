default:
	rm -rf build
	rm -rf calabash.framework
	scripts/make-calabash-lib-iphonesimulator.rb
	scripts/make-calabash-lib-iphoneos.rb
	scripts/make-calabash-lib-version.rb
	scripts/make-framework.rb verify

clean:
	rm -rf build
	rm -rf calabash.framework
