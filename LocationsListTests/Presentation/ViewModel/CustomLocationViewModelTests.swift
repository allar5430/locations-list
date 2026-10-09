import Foundation
import XCTest
@testable import LocationsList

@MainActor
final class CustomLocationViewModelTests: XCTestCase {
    func testAddCustomLocationSetsIdleAndSendsActionAfterSuccess() async {
        let router = StubRouter()
        var receivedActions: [CustomLocationAction] = []
        let viewModel = CustomLocationViewModel(
            addCustomLocationUseCase: StubAddCustomLocationUseCase(result: .success(())),
            router: router,
            onAction: { action in
                receivedActions.append(action)
            }
        )

        viewModel.didTapDone(locationName: "Amsterdam", isCurrentLocation: false)
        await waitUntil { router.didDismissSheet }

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(receivedActions, [.didAddLocation])
        XCTAssertTrue(router.didDismissSheet)
    }

    func testAddCustomLocationShowsFailureWhenGeocodingFails() async {
        let router = StubRouter()
        var receivedActions: [CustomLocationAction] = []
        let viewModel = CustomLocationViewModel(
            addCustomLocationUseCase: StubAddCustomLocationUseCase(result: .failure(TestError.failed)),
            router: router,
            onAction: { action in
                receivedActions.append(action)
            }
        )

        viewModel.didTapDone(locationName: "Missing Place", isCurrentLocation: false)
        await waitUntil { viewModel.state == .failed("Unable to find this location") }

        XCTAssertEqual(viewModel.state, .failed("Unable to find this location"))
        XCTAssertTrue(receivedActions.isEmpty)
        XCTAssertFalse(router.didDismissSheet)
    }

    func testAddCurrentLocationPassesCurrentFlagToUseCase() async {
        let useCase = SpyAddCustomLocationUseCase(result: .success(()))
        let viewModel = CustomLocationViewModel(
            addCustomLocationUseCase: useCase,
            router: StubRouter(),
            onAction: { _ in }
        )

        viewModel.didTapDone(locationName: "Home", isCurrentLocation: true)
        await waitForRequest(in: useCase)

        let firstRequest = await useCase.firstRequest
        let requestCount = await useCase.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(firstRequest?.name, "Home")
        XCTAssertEqual(firstRequest?.isCurrent, true)
    }

    func testCancelDismissesThroughRouter() {
        let router = StubRouter()
        let viewModel = CustomLocationViewModel(
            addCustomLocationUseCase: StubAddCustomLocationUseCase(result: .success(())),
            router: router,
            onAction: { _ in }
        )

        viewModel.didTapCancel()

        XCTAssertTrue(router.didDismissSheet)
    }

    func testEditAfterFailureResetsState() async {
        let viewModel = CustomLocationViewModel(
            addCustomLocationUseCase: StubAddCustomLocationUseCase(result: .failure(TestError.failed)),
            router: StubRouter(),
            onAction: { _ in }
        )

        viewModel.didTapDone(locationName: "Missing Place", isCurrentLocation: false)
        await waitUntil { viewModel.state == .failed("Unable to find this location") }
        viewModel.didEditAfterFailure()

        XCTAssertEqual(viewModel.state, .idle)
    }

    private func waitUntil(
        _ condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 {
            if condition() {
                return
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Timed out waiting for condition", file: file, line: line)
    }

    private func waitForRequest(
        in useCase: SpyAddCustomLocationUseCase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 {
            if await useCase.requestCount == 1 {
                return
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Timed out waiting for request", file: file, line: line)
    }
}

private struct StubAddCustomLocationUseCase: CustomLocationAdding {
    let result: Result<Void, Error>

    func addLocation(name: String, isCurrent: Bool) async throws {
        try result.get()
    }
}

private actor SpyAddCustomLocationUseCase: CustomLocationAdding {
    let result: Result<Void, Error>
    private(set) var requests: [(name: String, isCurrent: Bool)] = []

    init(result: Result<Void, Error>) {
        self.result = result
    }

    func addLocation(name: String, isCurrent: Bool) async throws {
        requests.append((name, isCurrent))
        try result.get()
    }

    var requestCount: Int {
        requests.count
    }

    var firstRequest: (name: String, isCurrent: Bool)? {
        requests.first
    }
}

private enum TestError: Error {
    case failed
}

@MainActor
private final class StubRouter: SheetDismissing {
    var didShowCustomLocation = false
    var didDismissSheet = false
    var openedLocations: [PlaceLocation] = []

    func dismissSheet() {
        didDismissSheet = true
    }
}
