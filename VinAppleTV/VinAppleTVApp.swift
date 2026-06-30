//
//  VinAppleTVApp.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 25/6/26.
//

import SwiftUI

@main
struct VinAppleTVApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
