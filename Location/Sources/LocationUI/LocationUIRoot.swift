import LocationDomain
import SwiftUI

package struct LocationUIDependencies {
    let loadLocations: LocationsLoading
    let resolvePendingNames: PendingLocationNamesResolving
    let addLocation: LocationAdding
    let locations: LocationsReadable

    package init(
        loadLocations: LocationsLoading,
        resolvePendingNames: PendingLocationNamesResolving,
        addLocation: LocationAdding,
        locations: LocationsReadable
    ) {
        self.loadLocations = loadLocations
        self.resolvePendingNames = resolvePendingNames
        self.addLocation = addLocation
        self.locations = locations
    }
}

package struct LocationUIRoot: View {
    private let dependencies: LocationUIDependencies
    @State private var router = LocationsListRouter()

    package init(dependencies: LocationUIDependencies) {
        self.dependencies = dependencies
    }

    package var body: some View {
        NavigationStackController(router: router) {
            LocationsListView(
                viewModel: LocationsListViewModel(
                    pendingLocationNamesUseCase: dependencies.resolvePendingNames,
                    loadLocationsUseCase: dependencies.loadLocations,
                    locationsProvider: dependencies.locations,
                    router: router
                )
            )
        } sheetContent: { route in
            switch route {
            case .customLocation(let route):
                NavigationView {
                    CustomLocationView(
                        viewModel: CustomLocationViewModel(
                            addLocationUseCase: dependencies.addLocation,
                            router: router,
                            onAction: route.onAction
                        )
                    )
                }
            }
        }
    }
}
