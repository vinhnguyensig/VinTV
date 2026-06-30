//
//  Package.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 30/6/26.
//

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VPPlayer",
    platforms: [.tvOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "VPPlayer", targets: ["VPPlayer"])
    ],
    targets: [
        .target(name: "VPPlayer"),
        .testTarget(name: "VPPlayerTests", dependencies: ["VPPlayer"])
    ]
)
