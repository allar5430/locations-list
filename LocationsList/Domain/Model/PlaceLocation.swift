import Foundation

struct PlaceCoordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

struct PlaceLocation: Identifiable, Equatable, Sendable {
    enum NameState: Equatable, Sendable {
        case present(String)
        case pending
        case failed
        
        var isPresent: Bool {
            switch self {
            case .present: return true
            default: return false
            }
        }
    }

    let id: UUID
    let coordinate: PlaceCoordinate
    var nameState: NameState

    var displayName: String {
        switch nameState {
        case .present(let name):
            return name
        case .pending, .failed:
            return Strings.string(for: .unknown)
        }
    }
    
    var displayCoordinates: String {
        "\(coordinate.longitude.preffix4DigitsAfterDot), \(coordinate.latitude.preffix4DigitsAfterDot)"
    }
}

nonisolated extension PlaceLocation {
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

extension Double {
    var preffix4DigitsAfterDot: String {
        // 4 digits after dot for coordinates is ~10m, which is enough for city detection
        formatted(.number.precision(.fractionLength(4)))
    }
}
