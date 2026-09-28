#!/bin/sh

# MIT License

# Copyright (c) 2021 Ybrid®, a Hybrid Dynamic Live Audio Technology

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# 
# Generates opus_swift.xcframework from opus.xcodeproj.
# Usage: no parameters, settings mostly defined in xcode project
# 

# Do not continue after a failed archive. Continuing would create and upload an
# empty ZIP, which looks like a successful release but cannot be consumed.
set -e

opts="SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES ENABLE_BITCODE=NO CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO"

dd=./DerivedData
archivesPath="$dd/Archives"
generatedPath="Products/Library/Frameworks"

# path and name of intermediatly built frameworks 
builtPath="$dd/Build/Products" 
framework=YbridOpus.framework

rm -rfd $dd
mkdir -p "$archivesPath"
mkdir -p "$builtPath" 

pj="-project opus-swift.xcodeproj"
libs=opus-swift/libs

# The opus_ios scheme links opus-swift/libs/libopus_ios.a for both the device and the
# simulator archive. prepare.sh produces a device-only libopus_ios.a plus a separate
# libopus_sim.a (arm64 + x86_64). We build the device archive first, then swap the
# simulator fat lib into place so the simulator archive links the matching slices
# (this is what gives the framework proper arm64 simulator support on Apple Silicon).

platform=iphoneos
scheme=opus_ios
echo "building for $platform..."
xcodebuild archive $pj -scheme $scheme -destination 'generic/platform=iOS' -derivedDataPath $dd \
    -archivePath "$archivesPath/$platform.xcarchive" ARCHS="arm64" $opts > "build-$platform.log"
cp -R "$archivesPath/$platform.xcarchive/$generatedPath" "$builtPath/Archive-$platform"

platform=iphonesimulator
scheme=opus_ios
echo "building for $platform..."
# swap in the simulator fat lib (arm64 + x86_64) for the simulator archive
cp "$libs/libopus_ios.a" "$libs/libopus_ios.a.device.bak"
cp "$libs/libopus_sim.a" "$libs/libopus_ios.a"
xcodebuild archive $pj -scheme $scheme -destination 'generic/platform=iOS Simulator' -derivedDataPath $dd \
    -archivePath "$archivesPath/$platform.xcarchive" ARCHS="arm64 x86_64" $opts > "build-$platform.log"
# restore the device lib
mv "$libs/libopus_ios.a.device.bak" "$libs/libopus_ios.a"
cp -R "$archivesPath/$platform.xcarchive/$generatedPath" "$builtPath/Archive-$platform"

# Mac Catalyst needs Xcode >= 11.0
platform=maccatalyst
scheme=opus_catalyst
echo "building for $platform..."
xcodebuild archive $pj -scheme $scheme -destination 'generic/platform=macOS,variant=Mac Catalyst' -derivedDataPath $dd \
    -archivePath "$archivesPath/$platform.xcarchive" ARCHS="arm64 x86_64" $opts > "build-$platform.log"
cp -R "$archivesPath/$platform.xcarchive/$generatedPath" "$builtPath/Archive-$platform"

platform=macosx
scheme=opus_macos
echo "building for $platform..."
xcodebuild archive $pj -scheme $scheme -destination 'generic/platform=macOS' -derivedDataPath $dd \
    -archivePath "$archivesPath/$platform.xcarchive" ARCHS="arm64 x86_64" $opts > "build-$platform.log"
cp -R "$archivesPath/$platform.xcarchive/$generatedPath" "$builtPath/Archive-$platform"

# name of final xcframework
xcframework=YbridOpus.xcframework
rm -rfd $xcframework

products=`ls $builtPath`
echo "generating $xcframework for \n$products\n..."

cmd="xcodebuild -quiet -create-xcframework "
for entry in $products; do
    platform="${entry#Archive-}"
    # xcodebuild requires an absolute path for -debug-symbols.
    dsym="$(pwd)/${archivesPath#./}/$platform.xcarchive/dSYMs/$framework.dSYM"

    cmd="$cmd -framework $builtPath/$entry/$framework "
    # Keep the matching dSYM in the XCFramework. Without it, client archives
    # cannot symbolicate crashes from YbridOpus and Xcode warns about missing
    # symbol information for this binary framework.
    if [ -d "$dsym" ]; then
        cmd="$cmd -debug-symbols $dsym "
    else
        echo "warning: dSYM not found for $platform: $dsym" >&2
    fi
done
cmd="$cmd -output $xcframework"
#echo "$cmd"
$cmd

echo "zip $xcframework including LICENSE file..."
cp LICENSE $xcframework
# -y preserves symlinks inside the macOS / Mac Catalyst versioned framework bundles
zip -q -r -y $xcframework.zip $xcframework
test -s "$xcframework.zip"
echo "done."
