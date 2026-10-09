//
//  FetchLocationAPITests.swift
//  LocationsListTests
//
//  Created by Allar-Oleksii Aleksandrovych on 22/10/2026.
//

import XCTest
@testable import LocationKit

final class FetchLocationAPITests: XCTestCase {
    var sut: FetchLocationAPI!
    var session: SessionMock!
    
    override func setUp() async throws {
        try await super.setUp()
        session = SessionMock()
        sut = await .init(session: session)
    }
    
    func testURLMatch() async throws {
        let url = try makeURL()
        
        do {
            _ = try await sut.fetchLocations()
            XCTFail("request should throw without status code and data")
        } catch {
            let request = await session.request
            let unwrapped = try XCTUnwrap(request)
            
            XCTAssertEqual(unwrapped.url, url)
        }
    }
    
    func testRequestFailProvideInvalidRequestError() async throws {
        let url = try makeURL()
        await session.setResponse(
            SessionMock.makeResponse(for: url, statusCode: 200)
        )
        do {
            _ = try await sut.fetchLocations()
            XCTFail("request should throw without status code and data")
        } catch {
            let request = await session.request
            let unwrapped = try XCTUnwrap(request)
            // data not provided
            XCTAssertEqual(error, FetchLocationsAPIError.decodingFailed)
        }
    }
    
    private func makeURL() throws -> URL {
        try XCTUnwrap(URL(string: "https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json"))
    }
}

/*
 await session.setResponse(
     session.makeResponse(for: url, statusCode: 200)
 )
 */
actor SessionMock: SessionProviding {
    var request: URLRequest?
    
    var data: Data?
    var response: URLResponse?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        self.request = request
        
        return (data ?? Data(), response ?? URLResponse())
    }
    
    func setResponse(_ response: URLResponse?) async {
        self.response = response
    }
    
    static func makeResponse(for url: URL, statusCode: Int) -> URLResponse? {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
    }
}
