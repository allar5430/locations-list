import Foundation
import os

protocol CurrentLocationProviding: Sendable {
    func addCurrentLocation(named name: String) async throws
}

actor CurrentLocationRepository: CurrentLocationProviding {
    private let api: CurrentLocationGetting
    private let cache: LocationsModifying
    private let logger = Logger.make(for: .repository(.currentLocation))

    init(api: CurrentLocationGetting, cache: LocationsModifying) {
        self.api = api
        self.cache = cache
    }

    func addCurrentLocation(named name: String) async throws {
        logger.info("Current location request started")

        let coordinate: PlaceCoordinate
        do {
            coordinate = try await api.getCurrentCoordinate()
        } catch {
            logger.error("Current location request failed: \(error.description)")
            throw error
        }

        await cache.add(.named(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ))
    }
}
