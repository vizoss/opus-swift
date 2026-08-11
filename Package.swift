// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "0.8.1"
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
            checksum: "fa1565028a8f7703f3f8f08d5202d0fb14531096fd6c5ea8a05c63647fc45380"
            )
    ]
)
