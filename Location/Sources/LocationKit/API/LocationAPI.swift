import CoreLocation
import Foundation
import LocationDomain

protocol LocationGeocoding: Sendable {
    func reverseGeocode(latitude: Double, longitude: Double) async throws(LocationGeocodingError) -> String
    func geocodeLocation(named name: String) async throws(LocationGeocodingError) -> PlaceCoordinate
}

package actor LocationAPI: LocationGeocoding {
    private let geocoder = CLGeocoder()

    package init() {}

    func reverseGeocode(
        latitude: Double,
        longitude: Double
    ) async throws(LocationGeocodingError) -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.reverseGeocodeLocation(location)
        } catch {
            throw .unavailable
        }

        if let locality = placemarks.compactMap(\.locality).first {
            return locality
        }

        if let name = placemarks.compactMap(\.name).first {
            return name
        }

        throw .nameNotFound
    }

    func geocodeLocation(named name: String) async throws(LocationGeocodingError) -> PlaceCoordinate {
        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.geocodeAddressString(name)
        } catch {
            throw .unavailable
        }

        guard let location = placemarks.compactMap(\.location).first else {
            throw .coordinateNotFound
        }

        return PlaceCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
}

enum LocationGeocodingError: Error, Equatable, Sendable, CustomStringConvertible {
    case nameNotFound
    case coordinateNotFound
    case unavailable
    
    var description: String {
        switch self {
        case .nameNotFound:
            return "Location name not found"
        case .coordinateNotFound:
            return "Location coordinates not found"
        case .unavailable:
            return "Location geocoding unavailable"
        }
    }
}
