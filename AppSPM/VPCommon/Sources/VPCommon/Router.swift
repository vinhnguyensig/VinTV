//
//  Router.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 26/6/26.
//

public enum AppRoute: Hashable, Sendable {
    case home
    case detail(contentID: String)
    case player(contentID: String, resumeSeconds: Double?)
    case favorites
}

@MainActor
public protocol Routing: AnyObject {
    var path: [AppRoute] { get }
    func navigate(to route: AppRoute)
    func reset()
}

@MainActor
public final class Router: Routing {
    public private(set) var path: [AppRoute] = []

    public init() {}

    public func navigate(to route: AppRoute) {
        path.append(route)
    }

    public func reset() {
        path.removeAll()
    }
}
