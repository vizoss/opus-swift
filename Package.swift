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
            checksum: "6dde91dc41491ba36f26ede9f82cb4864706a1d4ad5020409347bf60e3eb52f2"
            )
    ]
)
