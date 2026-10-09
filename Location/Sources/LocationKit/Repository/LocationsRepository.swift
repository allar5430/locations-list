import Foundation
import LocationDomain
import os

package final class LocationsRepository: LocationsLoadingRepository {
    private let api: LocationsFetching
    private let cache: LocationsModifying
    private let logger = Logger.make(for: .repository(.locations))

    package init(api: FetchLocationAPI, cache: LocationsCache) {
        self.api = api
        self.cache = cache
    }

    init(
        api: LocationsFetching,
        cache: LocationsModifying
    ) {
        self.api = api
        self.cache = cache
    }

    package func loadLocations() async throws(LoadLocationsError) {
        logger.info("Fetching locations started")
        
        let response: LocationsDTO
        do {
            response = try await api.fetchLocations()
        } catch {
            logger.error("Fetching locations failed: \(error.description)")
            throw .unavailable
        }

        let locations: [PlaceLocation] = response.locations.map { dto in
            if let name = dto.name {
                return .named(name: name, latitude: dto.lat, longitude: dto.long)
            }

            return .pending(latitude: dto.lat, longitude: dto.long)
        }

        await cache.updateLocations(locations)
    }
}
