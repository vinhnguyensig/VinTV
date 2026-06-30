//
//  VPPlayerTests.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 27/6/26.
//

import Testing
@testable import VPPlayer

@Test
@MainActor
func playerStartsIdle() {
    #expect(VideoPlayerService().state == .idle)
}
