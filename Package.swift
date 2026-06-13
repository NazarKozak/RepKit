// swift-tools-version: 6.0
//
//  Package.swift
//  RepCounterSDK
//
//  Created by Nazar Kozak on 05.06.2026.
//

import PackageDescription

let package = Package(
    name: "RepCounterSDK",
    platforms: [
        .iOS(.v17),
        .macOS(.v12)
    ],
    products: [
        .library(name: "RepCounterSDK", targets: ["RepCounterSDK"])
    ],
    targets: [
        .target(
            name: "RepCounterSDK",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "RepCounterSDKTests",
            dependencies: ["RepCounterSDK"]
        )
    ]
)
