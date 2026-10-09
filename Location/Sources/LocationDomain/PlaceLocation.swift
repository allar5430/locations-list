import Foundation

package struct PlaceCoordinate: Equatable, Sendable {
    package let latitude: Double
    package let longitude: Double

    package init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

package struct PlaceLocation: Identifiable, Equatable, Sendable {
    package enum NameState: Equatable, Sendable {
        case present(String)
        case pending
        case failed
        
        package var isPresent: Bool {
            switch self {
            case .present: return true
            default: return false
            }
        }
    }

    package let id: UUID
    package let coordinate: PlaceCoordinate
    package var nameState: NameState
}

package extension PlaceLocation {
    static func named(name: String, latitude: Double, longitude: Double) -> PlaceLocation {
        PlaceLocation(
            id: UUID(),
            coordinate: PlaceCoordinate(latitude: latitude, longitude: longitude),
            nameState: .present(name)
        )
    }

    static func pending(latitude: Double, longitude: Double) -> PlaceLocation {
        PlaceLocation(
            id: UUID(),
            coordinate: PlaceCoordinate(latitude: latitude, longitude: longitude),
            nameState: .pending
        )
    }
}
