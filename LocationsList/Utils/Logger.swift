import os

nonisolated enum PlacesLogCategory: CustomStringConvertible, Sendable {
    enum ViewModel: String, Sendable {
        case addCustomLocation
        case locationsList
    }

    enum UseCase: String, Sendable {
        case getLocations
    }

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

    case viewModel(ViewModel)
    case router
    case useCase(UseCase)
    case repository(Repository)
    case api(API)

    var description: String {
        switch self {
        case .viewModel(let viewModel):
            return "viewModel.\(viewModel.rawValue)"
        case .router:
            return "router"
        case .useCase(let useCase):
            return "useCase.\(useCase.rawValue)"
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
