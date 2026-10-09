import Foundation
import LocationDomain
import Observation

@Observable final class LocationsListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @ObservationIgnored private let pendingLocationNamesUseCase: PendingLocationNamesResolving
    @ObservationIgnored private let loadLocationsUseCase: LocationsLoading
    @ObservationIgnored private let locationsProvider: LocationsReadable
    @ObservationIgnored private let router: LocationsRouting

    private(set) var state: State = .idle

    var locations: [PlaceLocation] {
        locationsProvider.locations
    }

    var title: String { Strings.string(for: .places) }
    var addLocationTitle: String { Strings.string(for: .addLocation) }
    var loadingLocationsTitle: String { Strings.string(for: .loadingLocations) }
    var locationsUnavailableTitle: String { Strings.string(for: .locationsUnavailable) }
    var openWikipediaHint: String { Strings.string(for: .openWikipediaHint) }

    func displayName(for location: PlaceLocation) -> String {
        location.displayName
    }

    func displayCoordinates(for location: PlaceLocation) -> String {
        location.displayCoordinates
    }

    func coordinateAccessibilityLabel(for location: PlaceLocation) -> String {
        Strings.coordinateAccessibility(
            latitude: location.coordinate.latitude.formatted(.number.precision(.fractionLength(4))),
            longitude: location.coordinate.longitude.formatted(.number.precision(.fractionLength(4)))
        )
    }

    init(
        pendingLocationNamesUseCase: PendingLocationNamesResolving,
        loadLocationsUseCase: LocationsLoading,
        locationsProvider: LocationsReadable,
        router: LocationsRouting
    ) {
        self.pendingLocationNamesUseCase = pendingLocationNamesUseCase
        self.loadLocationsUseCase = loadLocationsUseCase
        self.locationsProvider = locationsProvider
        self.router = router
    }

    func loadLocations() async {
        state = .loading

        do {
            try await loadLocationsUseCase.loadLocations()
            state = .loaded
            await pendingLocationNamesUseCase.resolvePendingNames()
        } catch {
            state = .failed(Strings.string(for: .unableToLoadLocations))
        }
    }

    func didTapAddLocation() {
        router.showCustomLocation { [weak self] action in
            // Async action, if for real app we need call to backend to reload list of locations
            await self?.handleCustomLocationAction(action)
        }
    }

    func didTapLocation(_ location: PlaceLocation) {
        router.openWikipedia(for: location)
    }

    private func handleCustomLocationAction(_ action: CustomLocationAction) async {
        switch action {
        case .didAddLocation:
            if state == .idle {
                state = .loaded
            }
        }
    }
}

private extension PlaceLocation {
    var displayName: String {
        switch nameState {
        case .present(let name): name
        case .pending, .failed: Strings.string(for: .unknown)
        }
    }

    var displayCoordinates: String {
        "\(coordinate.longitude.formatted(.number.precision(.fractionLength(4)))), \(coordinate.latitude.formatted(.number.precision(.fractionLength(4))))"
    }
}
