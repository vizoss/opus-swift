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
# Builds per-slice static libopus libraries for a modern, complete XCFramework:
#   opus-swift/libs/libopus_ios.a       device        (arm64)
#   opus-swift/libs/libopus_sim.a       iOS simulator (arm64 + x86_64)
#   opus-swift/libs/libopus_osx.a       macOS         (arm64 + x86_64)
#   opus-swift/libs/libopus_catalyst.a  Mac Catalyst  (arm64 + x86_64)
# and copies the opus public headers into opus-swift/include.
#
# Preconditions:
# - Xcode command line tools installed (clang, xcrun, lipo)
#

opusDownload="https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz"
here=$(pwd)

mkdir -p opus-swift/libs
mkdir -p opus-swift/include

# resolve SDK paths (robust across Xcode versions / runners)
sdkPhone=$(xcrun --sdk iphoneos --show-sdk-path)
sdkSim=$(xcrun --sdk iphonesimulator --show-sdk-path)
sdkMac=$(xcrun --sdk macosx --show-sdk-path)

archive=`basename $opusDownload`
rm -f opus-*.tar.gz
if command -v wget >/dev/null 2>&1; then
    wget "$opusDownload"
else
    curl -L -o "$archive" "$opusDownload"
fi

libopusDir=`basename $opusDownload | sed "s/\.tar.gz$//"`
rm -rf $libopusDir
tar -xzf "$archive"
echo "opus sources ready in $libopusDir"
echo "==========================="

opuspath="$here/$libopusDir"
opusArtifact=.libs/libopus.a
opusHeaders="$opuspath/include"

tmp="$here/prepare"
fatLibsDest="$here/opus-swift/libs"

rm -rf "$tmp"
mkdir -p "$tmp"

# generateLibopus <label> <arch> <sdkpath> <host> <platform-flags...>
generateLibopus()
{
    label=$1
    arch=$2
    sdk=$3
    host=$4
    shift 4
    platformFlags="$@"

    product="libopus_${label}.a"
    logfile="$tmp/gen_${label}.log"
    echo "----------------------------"
    echo "generating $product (arch=$arch host=$host flags=$platformFlags) ..."

    cd "$opuspath"
    make clean >/dev/null 2>&1

    ./configure CC=clang --disable-shared --enable-static --with-pic \
        --enable-float-approx --disable-extra-programs --disable-doc \
        --host=$host \
        CFLAGS="-arch $arch -isysroot $sdk $platformFlags -Ofast -g -fPIC" \
        LDFLAGS="-arch $arch -isysroot $sdk $platformFlags" > "$logfile" 2>&1

    make -j$(sysctl -n hw.ncpu) >> "$logfile" 2>&1

    cp "$opuspath/$opusArtifact" "$tmp/$product"
    cd "$here"
    echo "generated $tmp/$product"
    lipo -info "$tmp/$product"
}

iosMin="12.0"
macMin="11.0"

# --- iOS device (arm64) ---
generateLibopus "ios_device_arm64" "arm64"  "$sdkPhone" "aarch64-apple-darwin" "-miphoneos-version-min=$iosMin"

# --- iOS simulator (arm64 + x86_64) ---
generateLibopus "ios_sim_arm64"    "arm64"  "$sdkSim"   "aarch64-apple-darwin" "-mios-simulator-version-min=$iosMin"
generateLibopus "ios_sim_x86_64"   "x86_64" "$sdkSim"   "x86_64-apple-darwin"  "-mios-simulator-version-min=$iosMin"

# --- macOS (arm64 + x86_64) ---
generateLibopus "mac_arm64"        "arm64"  "$sdkMac"   "aarch64-apple-darwin" "-mmacosx-version-min=$macMin"
generateLibopus "mac_x86_64"       "x86_64" "$sdkMac"   "x86_64-apple-darwin"  "-mmacosx-version-min=$macMin"

# --- Mac Catalyst (arm64 + x86_64) ---
generateLibopus "cat_arm64"        "arm64"  "$sdkMac"   "aarch64-apple-darwin" "-target arm64-apple-ios13.1-macabi"
generateLibopus "cat_x86_64"       "x86_64" "$sdkMac"   "x86_64-apple-darwin"  "-target x86_64-apple-ios13.1-macabi"

echo "==========================="
echo "combining slices with lipo ..."

# device: single-arch, used by the opus_ios scheme for the iphoneos archive
cp "$tmp/libopus_ios_device_arm64.a" "$fatLibsDest/libopus_ios.a"
# simulator fat lib, swapped in by build.sh before the iphonesimulator archive
lipo -create "$tmp/libopus_ios_sim_arm64.a" "$tmp/libopus_ios_sim_x86_64.a" -output "$fatLibsDest/libopus_sim.a"
# macOS fat lib
lipo -create "$tmp/libopus_mac_arm64.a" "$tmp/libopus_mac_x86_64.a" -output "$fatLibsDest/libopus_osx.a"
# Mac Catalyst fat lib
lipo -create "$tmp/libopus_cat_arm64.a" "$tmp/libopus_cat_x86_64.a" -output "$fatLibsDest/libopus_catalyst.a"

echo "--- resulting libs ---"
for l in libopus_ios.a libopus_sim.a libopus_osx.a libopus_catalyst.a; do
    echo "$l:"; lipo -info "$fatLibsDest/$l"
done

echo "==========================="
echo "copy headers into opus-swift/include"
for f in $opusHeaders/*.h; do
    cp -v "$f" "$here/opus-swift/include"
done

echo "opus-swift.xcodeproj is ready."
echo "done."
