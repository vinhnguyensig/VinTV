//
//  VPCommonTests.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 28/6/26.
//

import Testing
@testable import VPCommon

@Test
func screenViewEventUsesExpectedName() {
    let event = AnalyticsEvent.screenViewed(.detail, contentID: "movie-1")

    #expect(event.name == "screen_view_detail")
    #expect(event.properties == ["content_id": "movie-1"])
}

@Test
func seekEventProvidesReadableTypedProperties() {
    let event = AnalyticsEvent.playbackSeeked(
        contentID: "movie-1",
        fromSeconds: 12.9,
        toSeconds: 42.1
    )

    #expect(event.name == "playback_seek")
    #expect(event.properties["from_seconds"] == "12")
    #expect(event.properties["to_seconds"] == "42")
}
