import SwiftUI

@MainActor
enum PlacesScreenFactory {
    struct Dependencies {
        let getLocationsUseCase: LocationsLoading
        let addCustomLocationUseCase: CustomLocationAdding
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
        let useCase = GetLocationsUseCase(
            locationsRepository: locationsRepository,
            nameRepository: nameRepository,
            currentLocationRepository: currentLocationRepository,
            cachedLocationsProvider: cache
        )

        return Dependencies(
            getLocationsUseCase: useCase,
            addCustomLocationUseCase: useCase,
            locationsProvider: cache
        )
    }

    static func makeLocationsListScreen(
        router: LocationsListRouter,
        dependencies: Dependencies
    ) -> LocationsListView {
        let viewModel = LocationsListViewModel(
            getLocationsUseCase: dependencies.getLocationsUseCase,
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
            addCustomLocationUseCase: dependencies.addCustomLocationUseCase,
            router: router,
            onAction: onAction
        )

        return CustomLocationView(viewModel: viewModel)
    }
}
