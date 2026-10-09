import Foundation
import LocationDomain
import os

package final class LocationNameRepository: LocationNameResolving {
    private let api: LocationGeocoding
    private let cache: LocationsModifying
    private let logger = Logger.make(for: .repository(.locationName))

    package init(api: LocationAPI, cache: LocationsCache) {
        self.api = api
        self.cache = cache
    }

    init(
        api: LocationGeocoding,
        cache: LocationsModifying
    ) {
        self.api = api
        self.cache = cache
    }

    package func resolveName(for location: PlaceLocation) async {
        let nameState: PlaceLocation.NameState
        
        logger.info("Reverse geocoding started")

        do {
            let name = try await api.reverseGeocode(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            nameState = .present(name)
        } catch {
            logger.error("Reverse geocoding failed: \(error.description)")
            nameState = .failed
        }

        await cache.updateNameState(for: location.id, state: nameState)
    }

    package func addCustomLocation(named name: String) async throws(LocationNameError) {
        logger.info("Location geocoding started")

        let coordinate: PlaceCoordinate
        do {
            coordinate = try await api.geocodeLocation(named: name)
        } catch {
            logger.error("Location geocoding failed: \(error.description)")
            throw Self.locationNameError(from: error)
        }

        await cache.add(.named(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ))
    }

    private static func locationNameError(from error: LocationGeocodingError) -> LocationNameError {
        switch error {
        case .nameNotFound: .nameNotFound
        case .coordinateNotFound: .coordinateNotFound
        case .unavailable: .unavailable
        }
    }
}
