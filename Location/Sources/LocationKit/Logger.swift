import os

nonisolated enum PlacesLogCategory: CustomStringConvertible, Sendable {
    enum Repository: String, Sendable {
        case locations
        case locationName
        case currentLocation
    }

    enum API: String, Sendable {
        case fetchLocations
        case location
        case currentLocation
    }

    case repository(Repository)
    case api(API)

    var description: String {
        switch self {
        case .repository(let repository):
            return "repository.\(repository.rawValue)"
        case .api(let api):
            return "api.\(api.rawValue)"
        }
    }
}

nonisolated extension Logger {
    static func make(for category: PlacesLogCategory) -> Self {
        Logger(
            subsystem: "com.example.PlacesApp",
            category: category.description
        )
    }
}
