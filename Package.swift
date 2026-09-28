// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "0.8.3"
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
            checksum: "48d69ab26218635198c907d760524d53f2804b9eb28a4ef3f0ccabcd1ae01fcc"
            )
    ]
)
