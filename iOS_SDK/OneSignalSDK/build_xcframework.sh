WORKING_DIR=$(pwd)

PROJECT="${WORKING_DIR}/OneSignal.xcodeproj"
XA="xcodebuild archive -project ${PROJECT} -configuration 'Debug' -scheme OneSignalFramework"

OUTPUT_PATH="${WORKING_DIR}/Framework/OneSignal.xcframework"

${XA} -destination='platform=macOS,arch=x86_64,variant=Mac Catalyst' \
      -archivePath "OneSignal Catalyst.xcarchive" \
      SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
      clean 

${XA} -destination="iOS" -sdk iphoneos \
      -archivePath "OneSignal iOS.xcarchive" \
      SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
      clean 

${XA} -destination="platform=iOS Simulator,arch=x86_64" -sdk iphonesimulator \
      -archivePath "OneSignal iOS Simulator.xcarchive" \
      SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
      clean 

rm -rf ${OUTPUT_PATH}

xcodebuild -create-xcframework \
    -framework "OneSignal iOS.xcarchive/Products/Library/Frameworks/OneSignal.framework" \
    -framework "OneSignal iOS Simulator.xcarchive/Products/Library/Frameworks/OneSignal.framework" \
    -framework "OneSignal Catalyst.xcarchive/Products/Library/Frameworks/OneSignal.framework" \
    -output "${WORKING_DIR}/Framework/OneSignal.xcframework"
