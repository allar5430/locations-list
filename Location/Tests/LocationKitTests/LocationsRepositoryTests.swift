import Foundation
import XCTest
@testable import LocationKit
import LocationDomain

@MainActor
final class LocationsRepositoryTests: XCTestCase {
    private var sut: LocationsRepository!
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

    func testMapsNamedAndMissingNameLocations() async throws {
        let dto = LocationsDTO(locations: [
            TestPlaces.amsterdam.dto,
            TestPlaces.madrid.pendingDTO
        ])
        sut = LocationsRepository(api: StubFetchLocationsAPI(dto: dto), cache: cache)

        try await sut.loadLocations()
        let locations = cache.locations

        XCTAssertEqual(locations.count, 2)
        XCTAssertEqual(
            locations[0].nameState,
            .present(TestPlaces.amsterdam.name)
        )
        XCTAssertEqual(
            locations[0].coordinate,
            TestPlaces.amsterdam.coordinate
        )
        XCTAssertEqual(
            locations[1].nameState,
            .pending
        )
        XCTAssertEqual(
            locations[1].coordinate,
            TestPlaces.madrid.coordinate
        )
    }

    func testPropagatesMainRequestFailure() async throws {
        sut = LocationsRepository(api: FailingFetchLocationsAPI(), cache: cache)

        do {
            try await sut.loadLocations()
            XCTFail("Expected loadLocations to throw")
        } catch LoadLocationsError.unavailable {
            // Expected.
        } catch {
            XCTFail("Expected LoadLocationsError.unavailable, got \(error)")
        }
    }
}

private struct StubFetchLocationsAPI: LocationsFetching {
    let dto: LocationsDTO

    func fetchLocations() async throws(FetchLocationsAPIError) -> LocationsDTO {
        dto
    }
}

private struct FailingFetchLocationsAPI: LocationsFetching {
    func fetchLocations() async throws(FetchLocationsAPIError) -> LocationsDTO {
        throw .requestFailed
    }
}
