//
//  LocationsListApp.swift
//  LocationsList
//
//  Created by Allar-Oleksii Aleksandrovych on 08/10/2026.
//

import SwiftUI

@main public struct LocationsListApp: App {
    private let root = PlacesScreenFactory.makeRoot()
    
    public init() {}

    public var body: some Scene {
        WindowGroup {
            root
        }
    }
}
