import Foundation
import Observation

@Observable @MainActor final class LocationsListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @ObservationIgnored private let getLocationsUseCase: LocationsLoading
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

    func coordinateAccessibilityLabel(for location: PlaceLocation) -> String {
        Strings.coordinateAccessibility(
            latitude: location.coordinate.latitude.preffix4DigitsAfterDot,
            longitude: location.coordinate.longitude.preffix4DigitsAfterDot
        )
    }

    init(
        getLocationsUseCase: LocationsLoading,
        locationsProvider: LocationsReadable,
        router: LocationsRouting
    ) {
        self.getLocationsUseCase = getLocationsUseCase
        self.locationsProvider = locationsProvider
        self.router = router
    }

    func loadLocations() async {
        state = .loading

        do {
            try await getLocationsUseCase.loadLocations()
            state = .loaded
            await getLocationsUseCase.resolvePendingNames()
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
