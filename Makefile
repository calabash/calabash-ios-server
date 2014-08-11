XCPRETTY := $(shell gem list xcpretty -i)

default:

	if [ "${XCPRETTY}" = "false" ]; then gem install xcpretty; fi
	rm -rf build
	rm -rf calabash.framework

	xcrun xcodebuild -target "calabash-simulator" \
	                 -configuration Debug \
	                 SYMROOT=build \
	                 SDKROOT=iphonesimulator \
	                 IPHONEOS_DEPLOYMENT_TARGET=5.1.1 | xcpretty -c
	xcrun xcodebuild -target "calabash-device" \
	                 -configuration Debug \
	                 SYMROOT=build \
	                 SDKROOT=iphoneos \
	                 IPHONEOS_DEPLOYMENT_TARGET=5.1.1 | xcpretty -c
	xcrun xcodebuild -target "version" \
	                 -configuration Debug SYMROOT=build | xcpretty -c


	scripts/make-framework.rb verify

dylibs:
	mkdir -p build/Debug-iphonesimulator
	if [ "${XCPRETTY}" = "false" ]; then gem install xcpretty; fi
	xcrun xcodebuild -target "libCalabashDynSim" \
	                 -configuration Debug \
	                 SYMROOT=build \
	                 SDKROOT=iphonesimulator \
	                 IPHONEOS_DEPLOYMENT_TARGET=5.1.1 | xcpretty -c

	mkdir -p build/Debug-iphoneos
	xcrun xcodebuild -target "libCalabashDyn" \
	                 -configuration Debug \
	                 SYMROOT=build \
	                 SDKROOT=iphoneos \
	                 IPHONEOS_DEPLOYMENT_TARGET=5.1.1 | xcpretty -c

	scripts/make-framework.rb verify
clean:
	rm -rf build
	rm -rf calabash.framework
