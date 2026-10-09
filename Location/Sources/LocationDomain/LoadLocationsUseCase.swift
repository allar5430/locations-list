package final class LoadLocationsUseCase: LocationsLoading {
    private let repository: LocationsLoadingRepository

    package init(repository: LocationsLoadingRepository) {
        self.repository = repository
    }

    package func loadLocations() async throws(LoadLocationsError) {
        try await repository.loadLocations()
    }
}
