import Foundation

package protocol LocationAdding: Sendable {
    func addLocation(_ source: AddLocationSource) async throws(AddLocationUseCaseError)
}

package protocol PendingLocationNamesResolving: Sendable {
    func resolvePendingNames() async
}

package protocol LocationsLoading: Sendable {
    func loadLocations() async throws(LoadLocationsError)
}

package protocol LocationsLoadingRepository: Sendable {
    func loadLocations() async throws(LoadLocationsError)
}

package protocol LocationNameResolving: Sendable {
    func resolveName(for location: PlaceLocation) async
    func addCustomLocation(named name: String) async throws(LocationNameError)
}

package protocol CurrentLocationProviding: Sendable {
    func addCurrentLocation(named name: String) async throws(CurrentLocationError)
}

@MainActor
package protocol LocationsReadable: AnyObject, Sendable {
    var locations: [PlaceLocation] { get }
}
