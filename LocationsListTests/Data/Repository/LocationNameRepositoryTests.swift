import Foundation
import XCTest
@testable import LocationsList

@MainActor
final class LocationNameRepositoryTests: XCTestCase {
    func testWritesResolvedNameToCache() async {
        let cache = LocationsCache()
        cache.updateLocations([.pending(latitude: 40.4380, longitude: -3.7495)])
        let repository = LocationNameRepository(api: StubLocationAPI(reverseResult: .success("Madrid")), cache: cache)

        await repository.resolveName(for: cache.locations[0])

        XCTAssertEqual(cache.locations[0].nameState, .present("Madrid"))
    }

    func testWritesUnknownWhenReverseGeocodingFails() async {
        let cache = LocationsCache()
        cache.updateLocations([.pending(latitude: 0, longitude: 0)])
        let repository = LocationNameRepository(api: StubLocationAPI(reverseResult: .failure(.reverseGeocodingFailed)), cache: cache)

        await repository.resolveName(for: cache.locations[0])

        XCTAssertEqual(cache.locations[0].nameState, .failed)
    }

    func testGeocodesCustomLocationAndAddsItSortedToCache() async throws {
        let cache = LocationsCache()
        cache.updateLocations([.named(name: "London", latitude: 51.5072, longitude: -0.1276)])
        let repository = LocationNameRepository(
            api: StubLocationAPI(forwardResult: .success(PlaceCoordinate(latitude: 52.3676, longitude: 4.9041))),
            cache: cache
        )

        try await repository.addCustomLocation(named: "Amsterdam")

        XCTAssertEqual(cache.locations.map(\.displayName), ["Amsterdam", "London"])
        XCTAssertEqual(cache.locations[0].coordinate, PlaceCoordinate(latitude: 52.3676, longitude: 4.9041))
    }

    func testPropagatesCustomLocationGeocodingFailure() async {
        let cache = LocationsCache()
        let repository = LocationNameRepository(
            api: StubLocationAPI(forwardResult: .failure(.geocodingFailed)),
            cache: cache
        )

        do {
            try await repository.addCustomLocation(named: "Missing Place")
            XCTFail("Expected addCustomLocation to throw")
        } catch LocationNameError.geocodingFailed {
            XCTAssertTrue(cache.locations.isEmpty)
        } catch {
            XCTFail("Expected LocationNameError.geocodingFailed, got \(error)")
        }
    }
}

private struct StubLocationAPI: LocationGeocoding {
    let reverseResult: Result<String, LocationNameError>
    let forwardResult: Result<PlaceCoordinate, LocationNameError>

    init(
        reverseResult: Result<String, LocationNameError> = .success("Resolved"),
        forwardResult: Result<PlaceCoordinate, LocationNameError> = .success(PlaceCoordinate(latitude: 0, longitude: 0))
    ) {
        self.reverseResult = reverseResult
        self.forwardResult = forwardResult
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws(LocationNameError) -> String {
        try reverseResult.get()
    }

    func geocodeLocation(named name: String) async throws(LocationNameError) -> PlaceCoordinate {
        try forwardResult.get()
    }
}
