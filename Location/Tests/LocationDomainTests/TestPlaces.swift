import Foundation
@testable import LocationDomain

@MainActor
enum TestPlaces {
    static let amsterdam = TestPlace(
        name: "Amsterdam",
        coordinate: PlaceCoordinate(latitude: 52.3676, longitude: 4.9041)
    )
    static let london = TestPlace(
        name: "London",
        coordinate: PlaceCoordinate(latitude: 51.5072, longitude: -0.1276)
    )
    static let madrid = TestPlace(
        name: "Madrid",
        coordinate: PlaceCoordinate(latitude: 40.4380, longitude: -3.7495)
    )
    static let utrecht = TestPlace(
        name: "Utrecht",
        coordinate: PlaceCoordinate(latitude: 52.0907, longitude: 5.1214)
    )
    static let copenhagen = TestPlace(
        name: "Copenhagen",
        coordinate: PlaceCoordinate(latitude: 55.6713, longitude: 12.5237)
    )
    static let mumbai = TestPlace(
        name: "Mumbai",
        coordinate: PlaceCoordinate(latitude: 19.0823, longitude: 72.8111)
    )
    static let newYork = TestPlace(
        name: "New York",
        coordinate: PlaceCoordinate(latitude: 0, longitude: 0)
    )
    static let current = TestPlace(
        name: "Current",
        coordinate: amsterdam.coordinate
    )
    static let homeName = "Home"
    static let missingName = "Missing"
    static let missingPlaceName = "Missing Place"
    static let unableToFindLocationMessage = "Unable to find this location"
    static let unableToLoadLocationsMessage = "Unable to load locations"
    static let unknownDisplayName = "Unknown"
}

@MainActor
struct TestPlace {
    let name: String
    let coordinate: PlaceCoordinate

    var namedLocation: PlaceLocation {
        PlaceLocation.named(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    var pendingLocation: PlaceLocation {
        PlaceLocation.pending(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

}

@MainActor
final class TestLocationsCache: LocationsReadable {
    private(set) var locations: [PlaceLocation] = []

    func updateLocations(_ locations: [PlaceLocation]) {
        self.locations = sorted(locations)
    }

    func updateNameState(for id: PlaceLocation.ID, state: PlaceLocation.NameState) {
        guard let index = locations.firstIndex(where: { $0.id == id }) else { return }
        locations[index].nameState = state
        locations = sorted(locations)
    }

    func add(_ location: PlaceLocation) {
        locations.append(location)
        locations = sorted(locations)
    }

    private func sorted(_ locations: [PlaceLocation]) -> [PlaceLocation] {
        locations.sorted { first, second in
            switch (first.nameState, second.nameState) {
            case let (.present(firstName), .present(secondName)): firstName < secondName
            default: first.nameState.isPresent
            }
        }
    }
}

extension PlaceLocation {
    var testDisplayName: String {
        switch nameState {
        case .present(let name): name
        case .pending, .failed: "Unknown"
        }
    }
}
