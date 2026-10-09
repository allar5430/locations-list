import Foundation

package enum LoadLocationsError: Error, Equatable, Sendable {
    case unavailable
}

package enum LocationNameError: Error, Equatable, Sendable, CustomStringConvertible {
    case nameNotFound
    case coordinateNotFound
    case unavailable

    package var description: String {
        switch self {
        case .nameNotFound: "Location name not found"
        case .coordinateNotFound: "Location coordinates not found"
        case .unavailable: "Location geocoding unavailable"
        }
    }
}

package enum CurrentLocationError: Error, Equatable, Sendable, CustomStringConvertible {
    case permissionDenied
    case locationUnavailable

    package var description: String {
        switch self {
        case .permissionDenied: "Current location permission denied"
        case .locationUnavailable: "Current location unavailable"
        }
    }
}
