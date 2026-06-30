//
//  Package.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 28/6/26.
//

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VPCommon",
    platforms: [.tvOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "VPCommon", targets: ["VPCommon"])
    ],
    targets: [
        .target(name: "VPCommon"),
        .testTarget(name: "VPCommonTests", dependencies: ["VPCommon"])
    ]
)
