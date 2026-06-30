//
//  Package.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 26/6/26.
//

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VPLocalStorage",
    platforms: [.tvOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "VPLocalStorage", targets: ["VPLocalStorage"])
    ],
    targets: [
        .target(name: "VPLocalStorage"),
        .testTarget(name: "VPLocalStorageTests", dependencies: ["VPLocalStorage"])
    ]
)
