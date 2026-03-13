// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpotifyLogin",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "SpotifyLogin",
            targets: ["SpotifyLogin"]
        ),
    ],
    targets: [
        .target(
            name: "SpotifyLogin",
            path: "Sources",
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "SpotifyLoginTests",
            dependencies: ["SpotifyLogin"],
            path: "Tests",
            exclude: ["ObjCCompatibilityTests.m"]
        ),
        .testTarget(
            name: "SpotifyLoginObjCCompatibilityTests",
            dependencies: ["SpotifyLogin"],
            path: "Tests",
            sources: ["ObjCCompatibilityTests.m"]
        ),
    ]
)
