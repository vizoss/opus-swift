// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "0.8.2"
let package = Package(
    name: "YbridOpus",
    platforms: [
        .macOS(.v10_10), .iOS(.v9)
    ],
    products: [
        .library(
            name: "YbridOpus",
            targets: ["YbridOpus"]),
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "YbridOpus",
            url: "https://github.com/vizoss/opus-swift/releases/download/"+version+"/YbridOpus.xcframework.zip",
            checksum: "fb37a4d60e9cba1cd2bb37675f8711641529725981630123d435f1819fcbedb8"
            )
    ]
)
