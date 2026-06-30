//
//  Package.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 29/6/26.
//

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VPAppTheme",
    platforms: [.tvOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "VPAppTheme", targets: ["VPAppTheme"])
    ],
    targets: [
        .target(name: "VPAppTheme"),
        .testTarget(name: "VPAppThemeTests", dependencies: ["VPAppTheme"])
    ]
)
