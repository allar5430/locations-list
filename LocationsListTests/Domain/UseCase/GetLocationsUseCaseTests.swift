import Foundation
import XCTest
@testable import LocationsList

@MainActor
final class GetLocationsUseCaseTests: XCTestCase {
    func testLoadsLocationsImmediatelyAndResolvesMissingNames() async throws {
        let cache = LocationsCache()
        let locationsRepository = StubLocationsRepository(cache: cache, locations: [
            .named(name: "Amsterdam", latitude: 52.3547, longitude: 4.8339),
            .pending(latitude: 40.4380, longitude: -3.7495),
            .pending(latitude: 51.5072, longitude: -0.1276)
        ])
        let nameRepository = StubNameRepository(cache: cache, names: [
            40.4380: "Madrid",
            51.5072: "London"
        ])
        let useCase = GetLocationsUseCase(
            locationsRepository: locationsRepository,
            nameRepository: nameRepository,
            currentLocationRepository: StubCurrentLocationRepository(cache: cache),
            cachedLocationsProvider: cache
        )

        try await useCase.loadLocations()

        XCTAssertEqual(cache.locations.map(\.displayName), ["Amsterdam", "Unknown", "Unknown"])

        await useCase.resolvePendingNames()

        XCTAssertEqual(cache.locations.map(\.displayName), ["Amsterdam", "London", "Madrid"])
        XCTAssertTrue(cache.locations.allSatisfy {
            if case .present = $0.nameState {
                return true
            }
            return false
        })
    }

    func testSortsInitialNamedLocationsByName() {
        let cache = LocationsCache()

        cache.updateLocations([
            .named(name: "Mumbai", latitude: 19.0823, longitude: 72.8111),
            .pending(latitude: 40.4380, longitude: -3.7495),
            .named(name: "Amsterdam", latitude: 52.3547, longitude: 4.8339),
            .named(name: "Copenhagen", latitude: 55.6713, longitude: 12.5237)
        ])

        XCTAssertEqual(cache.locations.map(\.displayName), ["Amsterdam", "Copenhagen", "Mumbai", "Unknown"])
    }

    func testDoesNotMutateCacheWhenInitialRequestFails() async throws {
        let cache = LocationsCache()
        let useCase = GetLocationsUseCase(
            locationsRepository: FailingLocationsRepository(),
            nameRepository: StubNameRepository(cache: cache, names: [:]),
            currentLocationRepository: StubCurrentLocationRepository(cache: cache),
            cachedLocationsProvider: cache
        )

        do {
            try await useCase.loadLocations()
            XCTFail("Expected loadLocations to throw")
        } catch TestError.failed {
            XCTAssertTrue(cache.locations.isEmpty)
        } catch {
            XCTFail("Expected TestError.failed, got \(error)")
        }
    }

    func testAddsCustomLocationThroughNameRepository() async throws {
        let cache = LocationsCache()
        cache.updateLocations([.named(name: "London", latitude: 51.5072, longitude: -0.1276)])
        let nameRepository = StubNameRepository(cache: cache, names: [:], customLocations: [
            "Amsterdam": PlaceCoordinate(latitude: 52.3676, longitude: 4.9041)
        ])
        let useCase = GetLocationsUseCase(
            locationsRepository: StubLocationsRepository(locations: []),
            nameRepository: nameRepository,
            currentLocationRepository: StubCurrentLocationRepository(cache: cache),
            cachedLocationsProvider: cache
        )

        try await useCase.addLocation(name: " Amsterdam ", isCurrent: false)

        XCTAssertEqual(cache.locations.map(\.displayName), ["Amsterdam", "London"])
        XCTAssertEqual(cache.locations[0].coordinate, PlaceCoordinate(latitude: 52.3676, longitude: 4.9041))
    }

    func testAddsCurrentLocationThroughCurrentLocationRepository() async throws {
        let cache = LocationsCache()
        cache.updateLocations([.named(name: "London", latitude: 51.5072, longitude: -0.1276)])
        let useCase = GetLocationsUseCase(
            locationsRepository: StubLocationsRepository(locations: []),
            nameRepository: StubNameRepository(cache: cache, names: [:]),
            currentLocationRepository: StubCurrentLocationRepository(
                cache: cache,
                coordinate: PlaceCoordinate(latitude: 52.3676, longitude: 4.9041)
            ),
            cachedLocationsProvider: cache
        )

        try await useCase.addLocation(name: "Current", isCurrent: true)

        XCTAssertEqual(cache.locations.map(\.displayName), ["Current", "London"])
        XCTAssertEqual(cache.locations[0].coordinate, PlaceCoordinate(latitude: 52.3676, longitude: 4.9041))
    }
}

private struct StubLocationsRepository: LocationsProviding {
    let cache: LocationsModifying?
    let locations: [PlaceLocation]

    init(cache: LocationsModifying? = nil, locations: [PlaceLocation]) {
        self.cache = cache
        self.locations = locations
    }

    func loadLocations() async throws {
        if let cache {
            cache.updateLocations(locations)
        }
    }
}

private struct FailingLocationsRepository: LocationsProviding {
    func loadLocations() async throws {
        throw TestError.failed
    }
}

private actor StubNameRepository: LocationNameResolving {
    private let cache: LocationsCache
    private let names: [Double: String]
    private let customLocations: [String: PlaceCoordinate]

    init(cache: LocationsCache, names: [Double: String], customLocations: [String: PlaceCoordinate] = [:]) {
        self.cache = cache
        self.names = names
        self.customLocations = customLocations
    }

    func resolveName(for location: PlaceLocation) async {
        let latitude = await location.coordinate.latitude
        let id = await location.id
        let name = names[latitude, default: "Unknown"]
        await cache.updateNameState(for: id, state: .present(name))
    }

    func addCustomLocation(named name: String) async throws {
        guard let coordinate = customLocations[name] else {
            throw TestError.failed
        }

        await cache.add(.named(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}

private actor StubCurrentLocationRepository: CurrentLocationProviding {
    private let cache: LocationsCache
    private let coordinate: PlaceCoordinate

    init(
        cache: LocationsCache,
        coordinate: PlaceCoordinate = PlaceCoordinate(latitude: 0, longitude: 0)
    ) {
        self.cache = cache
        self.coordinate = coordinate
    }

    func addCurrentLocation(named name: String) async throws {
        await cache.add(.named(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ))
    }
}

private enum TestError: Error {
    case failed
}
