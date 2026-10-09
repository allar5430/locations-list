import Foundation

protocol LocationsLoading: Sendable {
    func loadLocations() async throws
    func resolvePendingNames() async
}

protocol CustomLocationAdding: Sendable {
    func addLocation(name: String, isCurrent: Bool) async throws
}

actor GetLocationsUseCase: LocationsLoading, CustomLocationAdding {
    private let locationsRepository: LocationsProviding
    private let nameRepository: LocationNameResolving
    private let currentLocationRepository: CurrentLocationProviding
    private let cachedLocationsProvider: LocationsReadable

    init(
        locationsRepository: LocationsProviding,
        nameRepository: LocationNameResolving,
        currentLocationRepository: CurrentLocationProviding,
        cachedLocationsProvider: LocationsReadable
    ) {
        self.locationsRepository = locationsRepository
        self.nameRepository = nameRepository
        self.currentLocationRepository = currentLocationRepository
        self.cachedLocationsProvider = cachedLocationsProvider
    }

    func loadLocations() async throws {
        try await locationsRepository.loadLocations()
    }

    func resolvePendingNames() async {
        let locations = await cachedLocationsProvider.locations
        await withTaskGroup(of: Void.self) { group in
            for location in locations {
                guard case .pending = location.nameState else { continue }
                group.addTask { [nameRepository] in
                    await nameRepository.resolveName(for: location)
                }
            }
        }
    }

    func addLocation(
        name: String,
        isCurrent: Bool
    ) async throws {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if isCurrent {
            try await currentLocationRepository.addCurrentLocation(named: normalizedName)
        } else {
            try await nameRepository.addCustomLocation(named: normalizedName)
        }
    }
}
