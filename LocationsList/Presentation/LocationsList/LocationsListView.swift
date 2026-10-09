import SwiftUI

struct LocationsListView: View {
    @State var viewModel: LocationsListViewModel

    var body: some View {
        content
            .navigationTitle(viewModel.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.didTapAddLocation()
                    } label: {
                        Label(viewModel.addLocationTitle, systemImage: "plus")
                    }
                }
            }
            .task {
                guard viewModel.state == .idle else { return }
                await viewModel.loadLocations()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loaded:
            List(viewModel.locations) { location in
                Button {
                    viewModel.didTapLocation(location)
                } label: {
                    TextContentRow(
                        state: .init(location: location),
                        title: location.displayName,
                        subtitle: location.displayCoordinates,
                        accessibilitySubtitle: viewModel.coordinateAccessibilityLabel(for: location)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint(viewModel.openWikipediaHint)
                .disabled(location.nameState == .pending)
            }
        case .idle, .loading:
            ProgressView(viewModel.loadingLocationsTitle)
        case .failed(let message):
            ContentUnavailableView(
                viewModel.locationsUnavailableTitle,
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }
}

private extension TextContentRow.RowState {
    init(location: PlaceLocation) {
        switch location.nameState {
        case .pending:
            self = .loading
        case .present:
            self = .active
        case .failed:
            self = .failed
        }
    }
}
