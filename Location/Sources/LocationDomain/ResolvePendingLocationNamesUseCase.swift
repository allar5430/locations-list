import Foundation

package final class ResolvePendingLocationNamesUseCase: PendingLocationNamesResolving {
    private let nameRepository: LocationNameResolving
    private let cachedLocationsProvider: LocationsReadable

    package init(
        nameRepository: LocationNameResolving,
        cachedLocationsProvider: LocationsReadable
    ) {
        self.nameRepository = nameRepository
        self.cachedLocationsProvider = cachedLocationsProvider
    }

    package func resolvePendingNames() async {
        let locations = await cachedLocationsProvider.locations
        await withTaskGroup(of: Void.self) { group in
            for location in locations {
                guard case .pending = location.nameState else { continue }
                group.addTask { [nameRepository] in
                    /// Apple explicitly mention not to start more then 1 request to geocoding service at a time, but I assumed our app can have more then 1 corrupted object and it's critical to resolve their names quickly. Most obvious solution - use other api, e.g. google provided api instead (paid if many requests) or call apple geocoding requests one by one. For this project, assumed that we just use some api which allows to do concurent calls, whatewer it is.
                    await nameRepository.resolveName(for: location)
                }
            }
        }
    }
}
