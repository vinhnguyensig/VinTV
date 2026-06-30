//
//  VPLocalStorageTests.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 26/6/26.
//

import Testing
@testable import VPLocalStorage

@Test
func keyValueStoreProtocolCanBeReferenced() {
    let store: KeyValueStoring = UserDefaultsKeyValueStore(defaults: .standard)
    _ = store.string(forKey: "missing")
}
