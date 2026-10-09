import Foundation
import os

nonisolated protocol CurrentLocationProviding: Sendable {
    func addCurrentLocation(named name: String) async throws(CurrentLocationError)
}

nonisolated final class CurrentLocationRepository: CurrentLocationProviding {
    private let api: CurrentLocationGetting
    private let cache: LocationsModifying
    private let logger = Logger.make(for: .repository(.currentLocation))

    init(api: CurrentLocationGetting, cache: LocationsModifying) {
        self.api = api
        self.cache = cache
    }

    nonisolated func addCurrentLocation(named name: String) async throws(CurrentLocationError) {
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
