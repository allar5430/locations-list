import Foundation
import LocationDomain
import os

package final class CurrentLocationRepository: CurrentLocationProviding {
    private let api: CurrentLocationGetting
    private let cache: LocationsModifying
    private let logger = Logger.make(for: .repository(.currentLocation))

    package init(api: CurrentLocationAPI, cache: LocationsCache) {
        self.api = api
        self.cache = cache
    }

    init(api: CurrentLocationGetting, cache: LocationsModifying) {
        self.api = api
        self.cache = cache
    }

    package func addCurrentLocation(named name: String) async throws(CurrentLocationError) {
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
