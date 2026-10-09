import Foundation
import XCTest
@testable import LocationUI
import LocationDomain

final class LocationsListViewModelTests: XCTestCase {
    private var sut: LocationsListViewModel!
    private var cache: TestLocationsCache!
    private var router: StubRouter!

    override func setUp() {
        super.setUp()
        cache = TestLocationsCache()
        router = StubRouter()
    }

    override func tearDown() {
        sut = nil
        cache = nil
        router = nil
        super.tearDown()
    }

    @MainActor func testLoadLocationsSetsLoadedState() async {
        cache.updateLocations([TestPlaces.amsterdam.namedLocation])
        makeSUT()

        await sut.loadLocations()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.locations.count, 1)
    }

    @MainActor func testLoadLocationsSetsFailedState() async {
        makeSUT(loadResult: .failure(.unavailable))

        await sut.loadLocations()

        XCTAssertEqual(sut.state, .failed(TestPlaces.unableToLoadLocationsMessage))
    }

    @MainActor func testDidTapLocationRoutesToWikipedia() {
        makeSUT()
        let location = TestPlaces.newYork.namedLocation

        sut.didTapLocation(location)

        XCTAssertEqual(router.openedLocations, [location])
    }

    @MainActor func testDidTapAddLocationRoutesToCustomLocationSheet() {
        makeSUT()

        sut.didTapAddLocation()

        XCTAssertTrue(router.didShowCustomLocation)
        XCTAssertNotNil(router.customLocationActionHandler)
    }

    @MainActor private func makeSUT(loadResult: Result<Void, LoadLocationsError> = .success(())) {
        sut = LocationsListViewModel(
            pendingLocationNamesUseCase: StubUseCase(),
            loadLocationsUseCase: StubLocationsUseCase(loadResult: loadResult),
            locationsProvider: cache,
            router: router
        )
    }
}

private struct StubUseCase: PendingLocationNamesResolving {
    func resolvePendingNames() async {}
}

private struct StubLocationsUseCase: LocationsLoading {
    let loadResult: Result<Void, LoadLocationsError>

    func loadLocations() async throws(LoadLocationsError) {
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
