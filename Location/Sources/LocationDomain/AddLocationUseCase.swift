import Foundation
import os.signpost

package enum AddLocationSource: Equatable, Sendable {
    case customName(String)
    case currentLocation(displayName: String)
}

package enum AddLocationUseCaseError: Error, Equatable, Sendable {
    case customLocationFailed(LocationNameError)
    case currentLocationFailed(CurrentLocationError)
}

package final class AddLocationUseCase: LocationAdding {
    private let nameRepository: LocationNameResolving
    private let currentLocationRepository: CurrentLocationProviding
    private let signposter = OSSignposter(subsystem: "com.myApp", category: .pointsOfInterest)
    
    package init(
        nameRepository: LocationNameResolving,
        currentLocationRepository: CurrentLocationProviding
    ) {
        self.nameRepository = nameRepository
        self.currentLocationRepository = currentLocationRepository
    }

    package func addLocation(_ source: AddLocationSource) async throws(AddLocationUseCaseError) {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("addLocation start", id: id)
        
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
                signposter.endInterval("addLocation end add current", state)
            } catch {
                signposter.endInterval("addLocation fail add current", state)
                throw .currentLocationFailed(error)
            }
        case .customName:
            do {
                try await nameRepository.addCustomLocation(named: normalizedName)
                signposter.endInterval("addLocation end add custom", state)
            } catch {
                signposter.endInterval("addLocation fail add custom", state)
                throw .customLocationFailed(error)
            }
        }
    }
}
