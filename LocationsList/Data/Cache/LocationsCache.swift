import Foundation
import Observation

@MainActor protocol LocationsReadable: AnyObject, Sendable {
    var locations: [PlaceLocation] { get }
}

@MainActor protocol LocationsModifying: AnyObject, Sendable {
    func updateLocations(_ locations: [PlaceLocation])
    func updateNameState(for id: PlaceLocation.ID, state: PlaceLocation.NameState)
    func add(_ location: PlaceLocation)
}

@Observable @MainActor final class LocationsCache: LocationsReadable, LocationsModifying {
    private(set) var locations: [PlaceLocation] = []

    func updateLocations(_ locations: [PlaceLocation]) {
        self.locations = sorted(locations)
    }

    func updateNameState(
        for id: PlaceLocation.ID,
        state: PlaceLocation.NameState
    ) {
        guard let index = locations.firstIndex(where: { $0.id == id }) else { return }
        locations[index].nameState = state
        locations = sorted(locations)
    }

    func add(_ location: PlaceLocation) {
        locations.append(location)
        locations = sorted(locations)
    }

    private func sorted(_ locations: [PlaceLocation]) -> [PlaceLocation] {
        locations.sorted { l1, l2 in
            switch (l1.nameState, l2.nameState) {
            case let (.present(name1), .present(name2)): return name1 < name2
            default: return l1.nameState.isPresent
            }
        }
    }
}
