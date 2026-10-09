import Foundation

nonisolated protocol LocationAdding: Sendable {
    func addLocation(_ source: AddLocationSource) async throws(AddLocationUseCaseError)
}

enum AddLocationSource: Equatable, Sendable {
    case customName(String)
    case currentLocation(displayName: String)
}

enum AddLocationUseCaseError: Error, Equatable, Sendable {
    case customLocationFailed(LocationNameError)
    case currentLocationFailed(CurrentLocationError)
}

nonisolated final class AddLocationUseCase: LocationAdding {
    private let nameRepository: LocationNameResolving
    private let currentLocationRepository: CurrentLocationProviding

    init(
        nameRepository: LocationNameResolving,
        currentLocationRepository: CurrentLocationProviding
    ) {
        self.nameRepository = nameRepository
        self.currentLocationRepository = currentLocationRepository
    }

    nonisolated func addLocation(_ source: AddLocationSource) async throws(AddLocationUseCaseError) {
        let name: String

        switch source {
        case let .customName(customName):
            name = customName
        case let .currentLocation(displayName):
            name = displayName
        }

        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        switch source {
        case .currentLocation:
            do {
                try await currentLocationRepository.addCurrentLocation(named: normalizedName)
            } catch {
                throw .currentLocationFailed(error)
            }
        case .customName:
            do {
                try await nameRepository.addCustomLocation(named: normalizedName)
            } catch {
                throw .customLocationFailed(error)
            }
        }
    }
}
