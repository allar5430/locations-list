import Foundation
import XCTest
@testable import LocationsList

@MainActor
final class LocationsListRouterTests: XCTestCase {
    func testOpenWikipediaOpensContinuationURLForResolvedLocation() {
        let opener = RecordingURLOpener()
        let router = LocationsListRouter()
        router.configure(urlOpener: opener)

        let location: PlaceLocation = .named(name: "New York", latitude: 52.3676, longitude: 4.9041)
        router.openWikipedia(for: location)

        XCTAssertEqual(opener.openedURLs.map(\.absoluteString), [
            "wikipedia://places?lat=52.3676&long=4.9041"
        ])
    }

    func testOpenWikipediaIgnoresPendingLocation() {
        let opener = RecordingURLOpener()
        let router = LocationsListRouter()
        router.configure(urlOpener: opener)

        let location: PlaceLocation = .pending(latitude: 0, longitude: 0)
        router.openWikipedia(for: location)

        XCTAssertTrue(opener.openedURLs.isEmpty)
    }
}

@MainActor
private final class RecordingURLOpener: ExternalURLOpening {
    private(set) var openedURLs: [URL] = []

    func open(_ url: URL) {
        openedURLs.append(url)
    }
}
