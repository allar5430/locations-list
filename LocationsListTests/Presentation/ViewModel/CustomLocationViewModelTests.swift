import Foundation
import XCTest
@testable import LocationsList

@MainActor
final class CustomLocationViewModelTests: XCTestCase {
    private var sut: CustomLocationViewModel!
    private var router: StubRouter!

    override func setUp() {
        super.setUp()
        router = StubRouter()
    }

    override func tearDown() {
        sut = nil
        router = nil
        super.tearDown()
    }

    func testDoneIsDisabledWhenLocationNameIsEmpty() {
        makeSUT()

        XCTAssertTrue(sut.isDoneDisabled)
    }

    func testDoneIsEnabledWhenLocationNameIsNotEmpty() {
        makeSUT()

        sut.locationName = TestPlaces.amsterdam.name

        XCTAssertFalse(sut.isDoneDisabled)
    }

    func testDidTapDoneSetsGeocodingState() {
        makeSUT()

        sut.didTapDone(
            locationName: TestPlaces.amsterdam.name,
            isCurrentLocation: false
        )

        XCTAssertEqual(sut.state, .geocoding)
        XCTAssertTrue(sut.isDoneDisabled)
    }

    func testCancelDismissesThroughRouter() {
        makeSUT()

        sut.didTapCancel()

        XCTAssertTrue(router.didDismissSheet)
    }

    func testCancelResetsStateAndDismissesThroughRouter() {
        makeSUT()
        sut.didTapDone(
            locationName: TestPlaces.amsterdam.name,
            isCurrentLocation: false
        )

        sut.didTapCancel()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(router.didDismissSheet)
    }

    private func makeSUT() {
        sut = CustomLocationViewModel(
            addLocationUseCase: NoopAddLocationUseCase(),
            router: router,
            onAction: { _ in }
        )
    }
}

private struct NoopAddLocationUseCase: LocationAdding {
    func addLocation(_ source: AddLocationSource) async throws(AddLocationUseCaseError) {
    }
}

@MainActor
private final class StubRouter: SheetDismissing {
    var didDismissSheet = false

    func dismissSheet() {
        didDismissSheet = true
    }
}
