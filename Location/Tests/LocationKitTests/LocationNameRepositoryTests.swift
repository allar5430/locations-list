import Foundation
import XCTest
@testable import LocationKit
import LocationDomain

@MainActor
final class LocationNameRepositoryTests: XCTestCase {
    private var sut: LocationNameRepository!
    private var cache: LocationsCache!

    override func setUp() {
        super.setUp()
        cache = LocationsCache()
    }

    override func tearDown() {
        sut = nil
        cache = nil
        super.tearDown()
    }

    func testWritesResolvedNameToCache() async {
        cache.updateLocations([TestPlaces.madrid.pendingLocation])
        sut = LocationNameRepository(
            api: StubLocationAPI(reverseResult: .success(TestPlaces.madrid.name)),
            cache: cache
        )

        await sut.resolveName(for: cache.locations[0])

        XCTAssertEqual(cache.locations[0].nameState, .present(TestPlaces.madrid.name))
    }

    func testWritesUnknownWhenReverseGeocodingFails() async {
        cache.updateLocations([TestPlaces.newYork.pendingLocation])
        sut = LocationNameRepository(
        api: StubLocationAPI(reverseResult: .failure(.unavailable)),
            cache: cache
        )

        await sut.resolveName(for: cache.locations[0])

        XCTAssertEqual(cache.locations[0].nameState, .failed)
    }

    func testGeocodesCustomLocationAndAddsItSortedToCache() async throws {
        cache.updateLocations([TestPlaces.london.namedLocation])
        sut = LocationNameRepository(
            api: StubLocationAPI(forwardResult: .success(TestPlaces.amsterdam.coordinate)),
            cache: cache
        )

        try await sut.addCustomLocation(named: TestPlaces.amsterdam.name)

        XCTAssertEqual(
            cache.locations.map(\.testName),
            [TestPlaces.amsterdam.name, TestPlaces.london.name]
        )
        XCTAssertEqual(
            cache.locations[0].coordinate,
            TestPlaces.amsterdam.coordinate
        )
    }

    func testPropagatesCustomLocationGeocodingFailure() async {
        sut = LocationNameRepository(
        api: StubLocationAPI(forwardResult: .failure(.unavailable)),
            cache: cache
        )

        do {
            try await sut.addCustomLocation(named: TestPlaces.missingPlaceName)
            XCTFail("Expected addCustomLocation to throw")
        } catch LocationNameError.unavailable {
            XCTAssertTrue(cache.locations.isEmpty)
        } catch {
            XCTFail("Expected LocationNameError.unavailable, got \(error)")
        }
    }
}

private struct StubLocationAPI: LocationGeocoding {
    let reverseResult: Result<String, LocationGeocodingError>
    let forwardResult: Result<PlaceCoordinate, LocationGeocodingError>

    init(
        reverseResult: Result<String, LocationGeocodingError> = .success("Resolved"),
        forwardResult: Result<PlaceCoordinate, LocationGeocodingError> = .success(PlaceCoordinate(latitude: 0, longitude: 0))
    ) {
        self.reverseResult = reverseResult
        self.forwardResult = forwardResult
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws(LocationGeocodingError) -> String {
        try reverseResult.get()
    }

    func geocodeLocation(named name: String) async throws(LocationGeocodingError) -> PlaceCoordinate {
        try forwardResult.get()
    }
}
