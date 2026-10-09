import SwiftUI
import os

enum CustomLocationAction {
    case didAddLocation
}

typealias CustomLocationActionHandler = @MainActor (CustomLocationAction) async -> Void

@MainActor
protocol LocationsRouting: AnyObject {
    func showCustomLocation(onAction: @escaping CustomLocationActionHandler)
    func openWikipedia(for location: PlaceLocation)
}

@MainActor
protocol SheetDismissing: AnyObject {
    func dismissSheet()
}

@Observable @MainActor final class LocationsListRouter: LocationsRouting, SheetDismissing, @MainActor NavigationStackControlling, OpenURLConfiguring {
    enum Route: Hashable {
        case locations
    }

    struct CustomLocationRoute: Identifiable, Sendable {
        let id = UUID()
        let onAction: CustomLocationActionHandler
    }

    enum SheetRoute: Identifiable, Sendable {
        case customLocation(CustomLocationRoute)
        
        var id: String {
            switch self {
            case .customLocation(let route):
                route.id.uuidString
            }
        }
    }

    var path = NavigationPath()
    var presentedSheet: SheetRoute?

    private let urlBuilder: WikipediaURLBuilding
    private var urlOpener: ExternalURLOpening?
    
    @ObservationIgnored private let logger = Logger.make(for: .router)

    init(
        urlBuilder: WikipediaURLBuilding = WikipediaContinuationURLBuilder(),
    ) {
        self.urlBuilder = urlBuilder
    }

    func configure(urlOpener: ExternalURLOpening) {
        self.urlOpener = urlOpener
    }

    func configure(openURL: OpenURLAction) {
        configure(urlOpener: SwiftUIExternalURLOpener(openURL: openURL))
    }

    func showCustomLocation(onAction: @escaping CustomLocationActionHandler) {
        presentedSheet = .customLocation(
            CustomLocationRoute(onAction: onAction)
        )
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func openWikipedia(for location: PlaceLocation) {
        guard let urlOpener else {
            logger.error("Can't open url, no opener configured")
            return
        }
        guard location.nameState != .pending else {
            logger.info("Opening Wikipedia skipped for pending location")
            return
        }

        guard let url = urlBuilder.url(for: location.coordinate) else {
            logger.error("Opening Wikipedia failed because URL could not be created")
            return
        }

        urlOpener.open(url)
    }
}
