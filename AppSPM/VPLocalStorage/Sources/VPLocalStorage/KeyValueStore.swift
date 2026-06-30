//
//  KeyValueStore.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 26/6/26.
//

import Foundation

public protocol KeyValueStoring: AnyObject {
    func string(forKey key: String) -> String?
    func set(_ value: String?, forKey key: String)
}

public final class UserDefaultsKeyValueStore: KeyValueStoring {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    public func set(_ value: String?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}
