//
//  VPCoreTests.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 25/6/26.
//

import Testing
@testable import VPCore

@Test
func moduleInfoStoresName() {
    #expect(ModuleInfo(name: "VPCore").name == "VPCore")
}
