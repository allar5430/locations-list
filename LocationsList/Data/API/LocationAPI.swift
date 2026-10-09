import CoreLocation
import Foundation

protocol LocationGeocoding: Sendable {
    func reverseGeocode(latitude: Double, longitude: Double) async throws(LocationNameError) -> String
    func geocodeLocation(named name: String) async throws(LocationNameError) -> PlaceCoordinate
}

actor LocationAPI: LocationGeocoding {
    private let geocoder = CLGeocoder()

    func reverseGeocode(
        latitude: Double,
        longitude: Double
    ) async throws(LocationNameError) -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.reverseGeocodeLocation(location)
        } catch {
            throw .reverseGeocodingFailed
        }

        if let locality = placemarks.compactMap(\.locality).first {
            return locality
        }

        if let name = placemarks.compactMap(\.name).first {
            return name
        }

        throw .nameNotFound
    }

    func geocodeLocation(named name: String) async throws(LocationNameError) -> PlaceCoordinate {
        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.geocodeAddressString(name)
        } catch {
            throw .geocodingFailed
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

enum LocationNameError: Error, Equatable, Sendable, CustomStringConvertible {
    case nameNotFound
    case coordinateNotFound
    case reverseGeocodingFailed
    case geocodingFailed

    var description: String {
        switch self {
        case .nameNotFound:
            return "Location name not found"
        case .coordinateNotFound:
            return "Location coordinates not found"
        case .reverseGeocodingFailed:
            return "Reverse geocoding failed"
        case .geocodingFailed:
            return "Location geocoding failed"
        }
    }
}
