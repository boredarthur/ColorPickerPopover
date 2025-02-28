// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ColorPickerPopover",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "ColorPickerPopover",
            targets: ["ColorPickerPopover"]
        ),
    ],
    targets: [
        .target(
            name: "ColorPickerPopover",
            path: "Sources/ColorPickerPopover"
        ),
    ]
)
