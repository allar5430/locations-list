import Foundation
import os

protocol LocationsProviding: Sendable {
    func loadLocations() async throws
}

actor LocationsRepository: LocationsProviding {
    private let api: LocationsFetching
    private let cache: LocationsModifying
    private lazy var logger = Logger.make(for: .repository(.locations))

    init(
        api: LocationsFetching,
        cache: LocationsModifying
    ) {
        self.api = api
        self.cache = cache
    }

    func loadLocations() async throws {
        logger.info("Fetching locations started")

        try await Task.sleep(nanoseconds: 1_000_000_000)
        
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
