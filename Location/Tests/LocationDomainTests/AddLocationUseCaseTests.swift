import Foundation
import XCTest
@testable import LocationDomain

@MainActor
final class AddLocationUseCaseTests: XCTestCase {
    private var sut: AddLocationUseCase!
    private var cache: TestLocationsCache!

    override func setUp() {
        super.setUp()
        cache = TestLocationsCache()
    }

    override func tearDown() {
        sut = nil
        cache = nil
        super.tearDown()
    }

    func testAddsCustomLocationThroughNameRepository() async throws {
        cache.updateLocations([TestPlaces.london.namedLocation])
        
        makeSUT(customLocations: [
            TestPlaces.amsterdam.name: TestPlaces.amsterdam.coordinate
        ])

        try await sut.addLocation(.customName(" \(TestPlaces.amsterdam.name) "))

        XCTAssertEqual(
            cache.locations.map(\.testDisplayName),
            [TestPlaces.amsterdam.name, TestPlaces.london.name]
        )
        XCTAssertEqual(
            cache.locations[0].coordinate, TestPlaces.amsterdam.coordinate
        )
    }

    func testAddsMultipleCustomLocationsThroughNameRepository() async throws {
        cache.updateLocations([TestPlaces.london.namedLocation])
        makeSUT(customLocations: [
            TestPlaces.amsterdam.name: TestPlaces.amsterdam.coordinate,
            TestPlaces.utrecht.name: TestPlaces.utrecht.coordinate
        ])

        try await sut.addLocation(.customName(TestPlaces.amsterdam.name))
        try await sut.addLocation(.customName(TestPlaces.utrecht.name))

        XCTAssertEqual(
            cache.locations.map(\.testDisplayName),
            [TestPlaces.amsterdam.name, TestPlaces.london.name, TestPlaces.utrecht.name]
        )
        XCTAssertEqual(
            cache.locations[0].coordinate,
            TestPlaces.amsterdam.coordinate
        )
        XCTAssertEqual(
            cache.locations[2].coordinate,
            TestPlaces.utrecht.coordinate
        )
    }

    func testAddsCurrentLocationThroughCurrentLocationRepository() async throws {
        cache.updateLocations([TestPlaces.london.namedLocation])
        makeSUT(currentCoordinate: TestPlaces.current.coordinate)

        try await sut.addLocation(.currentLocation(displayName: TestPlaces.current.name))

        XCTAssertEqual(
            cache.locations.map(\.testDisplayName),
            [TestPlaces.current.name, TestPlaces.london.name]
        )
        XCTAssertEqual(
            cache.locations[0].coordinate,
            TestPlaces.current.coordinate
        )
    }

    func testWrapsCustomLocationFailure() async {
        makeSUT(customLocations: [:])

        do {
            try await sut.addLocation(.customName(TestPlaces.missingName))
            XCTFail("Expected addLocation to throw")
        } catch AddLocationUseCaseError.customLocationFailed(.unavailable) {
        } catch {
            XCTFail("Expected unavailable, got \(error)")
        }
    }

    func testWrapsCurrentLocationFailure() async {
        makeSUT(currentResult: .failure(.permissionDenied))

        do {
            try await sut.addLocation(.currentLocation(displayName: TestPlaces.current.name))
            XCTFail("Expected addLocation to throw")
        } catch AddLocationUseCaseError.currentLocationFailed(.permissionDenied) {
        } catch {
            XCTFail("Expected permissionDenied, got \(error)")
        }
    }

    private func makeSUT(
        customLocations: [String: PlaceCoordinate] = [:],
        currentCoordinate: PlaceCoordinate = PlaceCoordinate(latitude: 0, longitude: 0)
    ) {
        sut = AddLocationUseCase(
            nameRepository: StubNameRepository(cache: cache, customLocations: customLocations),
            currentLocationRepository: StubCurrentLocationRepository(
                cache: cache,
                coordinate: currentCoordinate
            )
        )
    }

    private func makeSUT(
        customLocations: [String: PlaceCoordinate] = [:],
        currentResult: Result<PlaceCoordinate, CurrentLocationError>
    ) {
        sut = AddLocationUseCase(
            nameRepository: StubNameRepository(cache: cache, customLocations: customLocations),
            currentLocationRepository: StubCurrentLocationRepository(
                cache: cache,
                result: currentResult
            )
        )
    }
}

private actor StubNameRepository: LocationNameResolving {
    private let cache: TestLocationsCache
    private let customLocations: [String: PlaceCoordinate]

    init(cache: TestLocationsCache, customLocations: [String: PlaceCoordinate]) {
        self.cache = cache
        self.customLocations = customLocations
    }

    func resolveName(for location: PlaceLocation) async {}

    func addCustomLocation(named name: String) async throws(LocationNameError) {
        guard let coordinate = customLocations[name] else {
            throw .unavailable
        }

        await cache.add(.named(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}

private actor StubCurrentLocationRepository: CurrentLocationProviding {
    private let cache: TestLocationsCache
    private let result: Result<PlaceCoordinate, CurrentLocationError>

    init(
        cache: TestLocationsCache,
        coordinate: PlaceCoordinate = PlaceCoordinate(latitude: 0, longitude: 0)
    ) {
        self.cache = cache
        self.result = .success(coordinate)
    }

    init(
        cache: TestLocationsCache,
        result: Result<PlaceCoordinate, CurrentLocationError>
    ) {
        self.cache = cache
        self.result = result
    }

    func addCurrentLocation(named name: String) async throws(CurrentLocationError) {
        let coordinate = try result.get()
        await cache.add(.named(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ))
    }
}
