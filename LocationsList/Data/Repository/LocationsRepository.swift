import Foundation
import os

nonisolated protocol LocationsProviding: Sendable {
    func loadLocations() async throws(LocationsNetworkError)
}

nonisolated final class LocationsRepository: LocationsProviding {
    private let api: LocationsFetching
    private let cache: LocationsModifying
    private let logger = Logger.make(for: .repository(.locations))

    init(
        api: LocationsFetching,
        cache: LocationsModifying
    ) {
        self.api = api
        self.cache = cache
    }

    nonisolated func loadLocations() async throws(LocationsNetworkError) {
        logger.info("Fetching locations started")
        
        let response: LocationsDTO
        do {
            response = try await api.fetchLocations()
        } catch {
            logger.error("Fetching locations failed: \(error.description)")
            throw error
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
