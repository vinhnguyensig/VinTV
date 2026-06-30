//
//  Package.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 27/6/26.
//

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TVData",
    platforms: [.tvOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "TVData", targets: ["TVData"])
    ],
    dependencies: [
        .package(path: "../TVDomain")
    ],
    targets: [
        .target(
            name: "TVData",
            dependencies: [
                .product(name: "TVDomain", package: "TVDomain")
            ]
        ),
        .testTarget(
            name: "TVDataTests",
            dependencies: ["TVData"]
        )
    ]
)
