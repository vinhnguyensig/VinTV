//
//  Package.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 30/6/26.
//

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TVDomain",
    platforms: [.tvOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "TVDomain", targets: ["TVDomain"])
    ],
    targets: [
        .target(name: "TVDomain"),
        .testTarget(name: "TVDomainTests", dependencies: ["TVDomain"])
    ]
)
