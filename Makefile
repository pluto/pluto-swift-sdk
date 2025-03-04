PODSPEC := PlutoSwiftSDK.podspec
XCFRAMEWORK := PlutoSwiftSDK.xcframework

archive:
	# Clean up
	rm -rf archives; rm -rf PlutoSwiftSDK.xcframework

	# Build for iOS device
	xcodebuild archive \
		-scheme PlutoSwiftSDK \
		-destination "generic/platform=iOS" \
		-archivePath ./archives/ios_devices \
		SKIP_INSTALL=NO \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES

	# Build for iOS simulator
	xcodebuild archive \
		-scheme PlutoSwiftSDK \
		-destination "generic/platform=iOS Simulator" \
		-archivePath ./archives/ios_simulator \
		SKIP_INSTALL=NO \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES

	# Create the XCFramework
	xcodebuild -create-xcframework \
		-framework ./archives/ios_devices.xcarchive/Products/Library/Frameworks/PlutoSwiftSDK.framework \
		-framework ./archives/ios_simulator.xcarchive/Products/Library/Frameworks/PlutoSwiftSDK.framework \
		-output ./PlutoSwiftSDK.xcframework

release: archive
	# Zip the XCFramework appending the version to the filename
		@version=$$(grep -E '^[^#]*\.version\s*=' $(PODSPEC) \
		| sed -E 's/[^"]*"([^"]*)".*/\1/'); \
	echo "Zipping $(XCFRAMEWORK) as version $$version..."; \
	zip -r PlutoSwiftSDK-$$version.xcframework.zip $(XCFRAMEWORK)
	shasum -a 256 PlutoSwiftSDK-$$version.xcframework.zip

	# Clean up
	rm -rf archives; rm -rf PlutoSwiftSDK.xcframework

.PHONY: release archive
