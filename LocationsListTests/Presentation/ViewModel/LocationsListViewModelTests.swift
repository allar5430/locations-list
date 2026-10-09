import Foundation
import XCTest
@testable import LocationsList

@MainActor
final class LocationsListViewModelTests: XCTestCase {
    func testLoadLocationsSetsLoadedState() async {
        let cache = LocationsCache()
        cache.updateLocations([.named(name: "Amsterdam", latitude: 52.3547, longitude: 4.8339)])
        let viewModel = LocationsListViewModel(
            getLocationsUseCase: StubUseCase(loadResult: .success(())),
            locationsProvider: cache,
            router: StubRouter()
        )

        await viewModel.loadLocations()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.locations.count, 1)
    }

    func testLoadLocationsSetsFailedState() async {
        let viewModel = LocationsListViewModel(
            getLocationsUseCase: StubUseCase(loadResult: .failure(TestError.failed)),
            locationsProvider: LocationsCache(),
            router: StubRouter()
        )

        await viewModel.loadLocations()

        XCTAssertEqual(viewModel.state, .failed("Unable to load locations"))
    }

    func testDidTapLocationRoutesToWikipedia() {
        let router = StubRouter()
        let viewModel = LocationsListViewModel(
            getLocationsUseCase: StubUseCase(loadResult: .success(())),
            locationsProvider: LocationsCache(),
            router: router
        )
        let location = PlaceLocation.named(name: "New York", latitude: 0, longitude: 0)

        viewModel.didTapLocation(location)

        XCTAssertEqual(router.openedLocations, [location])
    }

    func testDidTapAddLocationRoutesToCustomLocationSheet() {
        let router = StubRouter()
        let viewModel = LocationsListViewModel(
            getLocationsUseCase: StubUseCase(),
            locationsProvider: LocationsCache(),
            router: router
        )

        viewModel.didTapAddLocation()

        XCTAssertTrue(router.didShowCustomLocation)
        XCTAssertNotNil(router.customLocationActionHandler)
    }
}

private struct StubUseCase: LocationsLoading {
    let loadResult: Result<Void, Error>

    init(loadResult: Result<Void, Error> = .success(())) {
        self.loadResult = loadResult
    }

    func loadLocations() async throws {
        try loadResult.get()
    }

    func resolvePendingNames() async {}
}

private enum TestError: Error {
    case failed
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
