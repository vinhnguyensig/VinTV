//
//  Package.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 26/6/26.
//

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VPCore",
    platforms: [.tvOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "VPCore", targets: ["VPCore"])
    ],
    targets: [
        .target(name: "VPCore"),
        .testTarget(name: "VPCoreTests", dependencies: ["VPCore"])
    ]
)
