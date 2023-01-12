// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parchment",
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ParchmentMmap",
            targets: ["ParchmentMmap", "Mmap", "MmapCDarwin"]),
        .library(
            name: "ParchmentFile",
            targets: ["ParchmentFile"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/OperatorFoundation/Chord", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Datable", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Gardener", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/ParchmentTypes", branch: "main"),
        .package(url: "https://github.com/ole/SortedArray.git", from: "0.7.0"),
        .package(url: "https://github.com/apple/swift-system", from: "1.2.1"),

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ParchmentMmap",
            dependencies: [
                "Chord",
                "Datable",
                "Gardener",
                "ParchmentTypes",
                "SortedArray",
                .product(name: "SystemPackage", package: "swift-system"),
                "Mmap",
            ]
        ),
        .target(
            name: "ParchmentFile",
            dependencies: [
                "Chord",
                "Datable",
                "Gardener",
                "ParchmentTypes",
                "SortedArray",
                .product(name: "SystemPackage", package: "swift-system"),
            ]
        ),
        .target(
            name: "Mmap",
            dependencies: [
                "MmapCDarwin",
                .product(name: "SystemPackage", package: "swift-system"),
            ]
        ),
        .target(name: "MmapCDarwin"),
        .testTarget(
            name: "ParchmentTests",
            dependencies: ["ParchmentMmap", "Mmap"]),
    ],
    swiftLanguageVersions: [.v5]
)
