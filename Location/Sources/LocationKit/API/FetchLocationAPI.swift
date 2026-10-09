import Foundation
import LocationDomain

protocol LocationsFetching: Sendable {
    func fetchLocations() async throws(FetchLocationsAPIError) -> LocationsDTO
}

protocol SessionProviding: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: SessionProviding {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}

package final class FetchLocationAPI: LocationsFetching {
    private enum Constants: Sendable {
        static let urlLiteral = "https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json"
    }
    
    private let session: any SessionProviding
    private let decoder = JSONDecoder()
    
    package init() {
        self.session = URLSession.shared
    }

    init(
        session: SessionProviding = URLSession.shared
    ) {
        self.session = session
    }

    func fetchLocations() async throws(FetchLocationsAPIError) -> LocationsDTO {
        guard let requestURL = URL(string: Constants.urlLiteral) else {
            throw .invalidURL
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: URLRequest(url: requestURL))
        } catch {
            throw .requestFailed
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw .invalidResponse
        }

        do {
            return try decoder.decode(LocationsDTO.self, from: data)
        } catch {
            throw .decodingFailed
        }
    }
}

nonisolated struct LocationsDTO: Decodable, Sendable {
    let locations: [LocationDTO]
}

nonisolated struct LocationDTO: Decodable, Sendable {
    let name: String?
    let lat: Double
    let long: Double
}

enum FetchLocationsAPIError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidURL
    case invalidResponse
    case requestFailed
    case decodingFailed

    var description: String {
        switch self {
        case .invalidURL:
            return "Invalid locations URL"
        case .invalidResponse:
            return "Invalid locations response"
        case .requestFailed:
            return "Locations request failed"
        case .decodingFailed:
            return "Locations response decoding failed"
        }
    }
}
