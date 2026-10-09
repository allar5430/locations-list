import SwiftUI

@MainActor
enum PlacesScreenFactory {
    struct Dependencies {
        let pendingLocationNamesUseCase: PendingLocationNamesResolving
        let addLocationUseCase: LocationAdding
        let locationsRepository: LocationsProviding
        let locationsProvider: LocationsReadable
    }

    static func makeDependencies() -> Dependencies {
        let cache = LocationsCache()
        let locationsRepository = LocationsRepository(api: FetchLocationAPI(), cache: cache)
        let nameRepository = LocationNameRepository(api: LocationAPI(), cache: cache)
        let currentLocationRepository = CurrentLocationRepository(
            api: CurrentLocationAPI(),
            cache: cache
        )
        let pendingLocationNamesUseCase = ResolvePendingLocationNamesUseCase(
            nameRepository: nameRepository,
            cachedLocationsProvider: cache
        )
        let addLocationUseCase = AddLocationUseCase(
            nameRepository: nameRepository,
            currentLocationRepository: currentLocationRepository
        )

        return Dependencies(
            pendingLocationNamesUseCase: pendingLocationNamesUseCase,
            addLocationUseCase: addLocationUseCase,
            locationsRepository: locationsRepository,
            locationsProvider: cache
        )
    }

    static func makeLocationsListScreen(
        router: LocationsListRouter,
        dependencies: Dependencies
    ) -> LocationsListView {
        let viewModel = LocationsListViewModel(
            pendingLocationNamesUseCase: dependencies.pendingLocationNamesUseCase,
            locationsRepository: dependencies.locationsRepository,
            locationsProvider: dependencies.locationsProvider,
            router: router
        )

        return LocationsListView(viewModel: viewModel)
    }

    static func makeCustomLocationScreen(
        router: SheetDismissing,
        dependencies: Dependencies,
        onAction: @escaping CustomLocationActionHandler
    ) -> CustomLocationView {
        let viewModel = CustomLocationViewModel(
            addLocationUseCase: dependencies.addLocationUseCase,
            router: router,
            onAction: onAction
        )

        return CustomLocationView(viewModel: viewModel)
    }
}
