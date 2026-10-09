import Foundation
@testable import LocationsList

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

    var dto: LocationDTO {
        LocationDTO(
            name: name,
            lat: coordinate.latitude,
            long: coordinate.longitude
        )
    }

    var pendingDTO: LocationDTO {
        LocationDTO(
            name: nil,
            lat: coordinate.latitude,
            long: coordinate.longitude
        )
    }
}
