//
//  LocationsListApp.swift
//  LocationsList
//
//  Created by Allar-Oleksii Aleksandrovych on 08/10/2026.
//

import SwiftUI

@main public struct LocationsListApp: App {
    private let locationsListRouter = LocationsListRouter()
    private let dependencies = PlacesScreenFactory.makeDependencies()
    
    public init() {}

    public var body: some Scene {
        WindowGroup {
            NavigationStackController(router: locationsListRouter) {
                PlacesScreenFactory.makeLocationsListScreen(
                    router: locationsListRouter,
                    dependencies: dependencies
                )
            } sheetContent: { route in
                switch route {
                case .customLocation(let route):
                    NavigationView {
                        PlacesScreenFactory.makeCustomLocationScreen(
                            router: locationsListRouter,
                            dependencies: dependencies,
                            onAction: route.onAction
                        )
                    }
                }
            }
        }
    }
}

