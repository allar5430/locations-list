import LocationDomain
import LocationKit
import LocationUI

enum PlacesScreenFactory {
    static func makeRoot() -> LocationUIRoot {
        let cache = LocationsCache()
        let locationsRepository = LocationsRepository(
            api: FetchLocationAPI(),
            cache: cache
        )
        let nameRepository = LocationNameRepository(
            api: LocationAPI(),
            cache: cache
        )
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
        let loadLocationUseCase = LoadLocationsUseCase(repository: locationsRepository)
        
        return LocationUIRoot(
            dependencies: LocationUIDependencies(
                loadLocations: loadLocationUseCase,
                resolvePendingNames: pendingLocationNamesUseCase,
                addLocation: addLocationUseCase,
                locations: cache
            )
        )
    }
}
