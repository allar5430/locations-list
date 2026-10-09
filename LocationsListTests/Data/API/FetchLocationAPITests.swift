import Foundation
import XCTest
@testable import LocationsList

final class FetchLocationAPITests: XCTestCase {
    func testExposesNetworkErrorDescriptions() {
        XCTAssertEqual(LocationsNetworkError.invalidURL.description, "Invalid locations URL")
        XCTAssertEqual(LocationsNetworkError.invalidResponse.description, "Invalid locations response")
        XCTAssertEqual(LocationsNetworkError.requestFailed.description, "Locations request failed")
        XCTAssertEqual(LocationsNetworkError.decodingFailed.description, "Locations response decoding failed")
    }
}
