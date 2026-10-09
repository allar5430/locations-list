import LocationDomain

@MainActor
enum TestPlaces {
    static let amsterdam = TestPlace(name: "Amsterdam", latitude: 52.3676, longitude: 4.9041)
    static let newYork = TestPlace(name: "New York", latitude: 0, longitude: 0)
    static let unableToLoadLocationsMessage = "Unable to load locations"
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
}

@MainActor
final class TestLocationsCache: LocationsReadable {
    private(set) var locations: [PlaceLocation] = []

    func updateLocations(_ locations: [PlaceLocation]) {
        self.locations = locations
    }
}
