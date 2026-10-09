import Foundation

protocol WikipediaURLBuilding {
    func url(for location: PlaceCoordinate) -> URL?
}

struct WikipediaContinuationURLBuilder: WikipediaURLBuilding {
    func url(for coordinate: PlaceCoordinate) -> URL? {
        var url = URLComponents()
        url.scheme = "wikipedia"
        url.host = "places"
        url.queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "long", value: String(coordinate.longitude))
        ]

        return url.url
    }
}
