import Foundation
import XCTest
@testable import LocationsList

@MainActor
final class LocationsListViewModelTests: XCTestCase {
    private var sut: LocationsListViewModel!
    private var cache: LocationsCache!
    private var router: StubRouter!

    override func setUp() {
        super.setUp()
        cache = LocationsCache()
        router = StubRouter()
    }

    override func tearDown() {
        sut = nil
        cache = nil
        router = nil
        super.tearDown()
    }

    func testLoadLocationsSetsLoadedState() async {
        cache.updateLocations([TestPlaces.amsterdam.namedLocation])
        makeSUT()

        await sut.loadLocations()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.locations.count, 1)
    }

    func testLoadLocationsSetsFailedState() async {
        makeSUT(loadResult: .failure(.requestFailed))

        await sut.loadLocations()

        XCTAssertEqual(sut.state, .failed(TestPlaces.unableToLoadLocationsMessage))
    }

    func testDidTapLocationRoutesToWikipedia() {
        makeSUT()
        let location = TestPlaces.newYork.namedLocation

        sut.didTapLocation(location)

        XCTAssertEqual(router.openedLocations, [location])
    }

    func testDidTapAddLocationRoutesToCustomLocationSheet() {
        makeSUT()

        sut.didTapAddLocation()

        XCTAssertTrue(router.didShowCustomLocation)
        XCTAssertNotNil(router.customLocationActionHandler)
    }

    private func makeSUT(loadResult: Result<Void, LocationsNetworkError> = .success(())) {
        sut = LocationsListViewModel(
            pendingLocationNamesUseCase: StubUseCase(),
            locationsRepository: StubLocationsRepository(loadResult: loadResult),
            locationsProvider: cache,
            router: router
        )
    }
}

private struct StubUseCase: PendingLocationNamesResolving {
    func resolvePendingNames() async {}
}

private struct StubLocationsRepository: LocationsProviding {
    let loadResult: Result<Void, LocationsNetworkError>

    func loadLocations() async throws(LocationsNetworkError) {
        try loadResult.get()
    }
}

@MainActor
private final class StubRouter: LocationsRouting {
    var didShowCustomLocation = false
    var didDismissSheet = false
    var openedLocations: [PlaceLocation] = []
    var customLocationActionHandler: CustomLocationActionHandler?

    func showCustomLocation(onAction: @escaping CustomLocationActionHandler) {
        didShowCustomLocation = true
        customLocationActionHandler = onAction
    }

    func dismissSheet() {
        didDismissSheet = true
    }

    func openWikipedia(for location: PlaceLocation) {
        openedLocations.append(location)
    }
}
