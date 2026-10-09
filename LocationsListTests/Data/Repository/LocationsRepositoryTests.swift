import Foundation
import XCTest
@testable import LocationsList

@MainActor
final class LocationsRepositoryTests: XCTestCase {
    func testMapsNamedAndMissingNameLocations() async throws {
        let dto = LocationsDTO(locations: [
            LocationDTO(name: "Amsterdam", lat: 52.3547498, long: 4.8339215),
            LocationDTO(name: nil, lat: 40.4380638, long: -3.7495758)
        ])
        let cache = LocationsCache()
        let repository = LocationsRepository(api: StubFetchLocationsAPI(dto: dto), cache: cache)

        try await repository.loadLocations()
        let locations = cache.locations

        XCTAssertEqual(locations.count, 2)
        XCTAssertEqual(locations[0].nameState, .present("Amsterdam"))
        XCTAssertEqual(locations[0].coordinate, PlaceCoordinate(latitude: 52.3547498, longitude: 4.8339215))
        XCTAssertEqual(locations[1].nameState, .pending)
        XCTAssertEqual(locations[1].coordinate, PlaceCoordinate(latitude: 40.4380638, longitude: -3.7495758))
    }

    func testPropagatesMainRequestFailure() async throws {
        let repository = LocationsRepository(api: FailingFetchLocationsAPI(), cache: LocationsCache())

        do {
            try await repository.loadLocations()
            XCTFail("Expected loadLocations to throw")
        } catch LocationsNetworkError.requestFailed {
            // Expected.
        } catch {
            XCTFail("Expected LocationsNetworkError.requestFailed, got \(error)")
        }
    }
}

private struct StubFetchLocationsAPI: LocationsFetching {
    let dto: LocationsDTO

    func fetchLocations() async throws(LocationsNetworkError) -> LocationsDTO {
        dto
    }
}

private struct FailingFetchLocationsAPI: LocationsFetching {
    func fetchLocations() async throws(LocationsNetworkError) -> LocationsDTO {
        throw .requestFailed
    }
}
