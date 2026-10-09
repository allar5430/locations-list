import LocationDomain
@testable import LocationKit

@MainActor
enum TestPlaces {
    static let amsterdam = TestPlace(name: "Amsterdam", latitude: 52.3676, longitude: 4.9041)
    static let london = TestPlace(name: "London", latitude: 51.5072, longitude: -0.1276)
    static let madrid = TestPlace(name: "Madrid", latitude: 40.4380, longitude: -3.7495)
    static let newYork = TestPlace(name: "New York", latitude: 0, longitude: 0)
    static let missingPlaceName = "Missing Place"
}

@MainActor
struct TestPlace {
    let name: String
    let coordinate: PlaceCoordinate

    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        coordinate = PlaceCoordinate(latitude: latitude, longitude: longitude)
    }

    var namedLocation: PlaceLocation {
        .named(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    var pendingLocation: PlaceLocation {
        .pending(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    var dto: LocationDTO {
        LocationDTO(name: name, lat: coordinate.latitude, long: coordinate.longitude)
    }

    var pendingDTO: LocationDTO {
        LocationDTO(name: nil, lat: coordinate.latitude, long: coordinate.longitude)
    }
}

extension PlaceLocation {
    var testName: String {
        guard case .present(let name) = nameState else { return "Unknown" }
        return name
    }
}
