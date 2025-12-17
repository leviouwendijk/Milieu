// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Milieu",
    products: [
        .library(
            name: "Milieu",
            targets: ["Milieu"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Variables.git", branch: "master")
    ],
    targets: [
        .target(
            name: "Milieu",
            dependencies: [
                .product(name: "Variables", package: "Variables")
            ]
        ),
        .testTarget(
            name: "MilieuTests",
            dependencies: ["Milieu"]
        ),
    ]
)
