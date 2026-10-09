import Foundation
import Observation
import os

@Observable @MainActor final class CustomLocationViewModel {
    enum State: Equatable {
        case idle
        case geocoding
        case failed(String)
    }

    private let addCustomLocationUseCase: CustomLocationAdding
    private let router: SheetDismissing
    private let onAction: CustomLocationActionHandler

    private(set) var state: State = .idle
    var locationName = ""
    var usesCurrentLocation = false

    var title: String { Strings.string(for: .customLocation) }
    var toggleTitle: String { Strings.string(for: .useCurrentLocation) }
    var cancelTitle: String { Strings.string(for: .cancel) }
    var doneTitle: String { Strings.string(for: .done) }
    var locationPlaceholder: String { Strings.string(for: .location) }
    
    private var addLocationTask: Task<Void, Never>?
    
    var isDoneDisabled: Bool {
        if locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        switch state {
        case .geocoding, .failed:
            return true
        case .idle:
            return false
        }
    }

    init(
        addCustomLocationUseCase: CustomLocationAdding,
        router: SheetDismissing,
        onAction: @escaping CustomLocationActionHandler
    ) {
        self.addCustomLocationUseCase = addCustomLocationUseCase
        self.router = router
        self.onAction = onAction
    }

    isolated deinit {
        addLocationTask?.cancel()
    }
    
    func didTapCancel() {
        state = .idle
        addLocationTask?.cancel()
        addLocationTask = nil
        router.dismissSheet()
    }

    func didTapDone(locationName: String, isCurrentLocation: Bool) {
        state = .geocoding

        addLocationTask?.cancel()
        
        addLocationTask = Task { [weak self, addCustomLocationUseCase] in
            guard !Task.isCancelled else {
                Logger.addCustomLocation.warning("Add custom location was cancelled")
                return
            }
            
            do {
                try await addCustomLocationUseCase.addLocation(
                    name: locationName,
                    isCurrent: isCurrentLocation
                )
                // task can still be cancelled, acepted as edge case
                await self?.handleAddingSuccess()
            } catch is CancellationError {
                // Case of hide modal while task is in progress
                Logger.addCustomLocation.warning("Add custom location was cancelled")
                return
            } catch {
                self?.state = .failed(Strings.string(for: .unableToFindLocation))
            }
        }
    }

    func didEditAfterFailure() {
        state = .idle
    }

    func didChangeLocationMode() {
        if case .failed = state {
            state = .idle
        }
    }
    
    private func handleAddingSuccess() async {
        // For real app - do call to backend to save location as well
        state = .idle
        // Reload list of remote locations
        await onAction(.didAddLocation)
        router.dismissSheet()
    }
}

private extension Logger {
    static let addCustomLocation = Logger.make(for: .viewModel(.addCustomLocation))
}
