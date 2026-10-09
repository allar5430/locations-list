import Foundation
import XCTest
@testable import LocationsList

@MainActor
final class ResolvePendingLocationNamesUseCaseTests: XCTestCase {
    private var sut: ResolvePendingLocationNamesUseCase!
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

    func testLoadsLocationsImmediatelyAndResolvesMissingNames() async throws {
        let locationsRepository = StubLocationsRepository(cache: cache, locations: [
            TestPlaces.amsterdam.namedLocation,
            TestPlaces.madrid.pendingLocation,
            TestPlaces.london.pendingLocation
        ])
        makeSUT(names: [
            TestPlaces.madrid.coordinate.latitude: TestPlaces.madrid.name,
            TestPlaces.london.coordinate.latitude: TestPlaces.london.name
        ])

        try await locationsRepository.loadLocations()

        XCTAssertEqual(
            cache.locations.map(\.displayName),
            [TestPlaces.amsterdam.name, TestPlaces.unknownDisplayName, TestPlaces.unknownDisplayName]
        )

        await sut.resolvePendingNames()

        XCTAssertEqual(
            cache.locations.map(\.displayName),
            [TestPlaces.amsterdam.name, TestPlaces.london.name, TestPlaces.madrid.name]
        )
        XCTAssertTrue(cache.locations.allSatisfy {
            if case .present = $0.nameState {
                return true
            }
            return false
        })
    }

    func testSortsInitialNamedLocationsByName() {
        cache.updateLocations([
            TestPlaces.mumbai.namedLocation,
            TestPlaces.madrid.pendingLocation,
            TestPlaces.amsterdam.namedLocation,
            TestPlaces.copenhagen.namedLocation
        ])

        XCTAssertEqual(
            cache.locations.map(\.displayName),
            [
                TestPlaces.amsterdam.name,
                TestPlaces.copenhagen.name,
                TestPlaces.mumbai.name,
                TestPlaces.unknownDisplayName
            ]
        )
    }
    
    private func makeSUT(names: [Double: String] = [:]) {
        sut = ResolvePendingLocationNamesUseCase(
            nameRepository: StubNameRepository(
                cache: cache,
                names: names,
                fallbackName: TestPlaces.unknownDisplayName
            ),
            cachedLocationsProvider: cache
        )
    }
}

private struct StubLocationsRepository: LocationsProviding {
    let cache: LocationsModifying?
    let locations: [PlaceLocation]

    init(cache: LocationsModifying? = nil, locations: [PlaceLocation]) {
        self.cache = cache
        self.locations = locations
    }

    func loadLocations() async throws(LocationsNetworkError) {
        if let cache {
            await cache.updateLocations(locations)
        }
    }
}

private actor StubNameRepository: LocationNameResolving {
    private let cache: LocationsCache
    private let names: [Double: String]
    private let fallbackName: String

    init(cache: LocationsCache, names: [Double: String], fallbackName: String) {
        self.cache = cache
        self.names = names
        self.fallbackName = fallbackName
    }

    func resolveName(for location: PlaceLocation) async {
        let latitude = await location.coordinate.latitude
        let id = await location.id
        let name = names[latitude, default: fallbackName]
        await cache.updateNameState(for: id, state: .present(name))
    }

    func addCustomLocation(named name: String) async throws(LocationNameError) {
        throw .geocodingFailed
    }
}
