import Foundation
import os
import SwiftUI

protocol ExternalURLOpening {
    func open(_ url: URL)
}

struct SwiftUIExternalURLOpener: ExternalURLOpening {
    private let openURL: OpenURLAction
    private let logger = Logger.locationUIRouter

    init(openURL: OpenURLAction) {
        self.openURL = openURL
    }

    func open(_ url: URL) {
        openURL(url) { accepted in
            if !accepted {
                let redactedURL = url.removingQueryParameters?.absoluteString ?? ""
                // As an improvement - show some error UI for this
                logger.error("Opening URL failed: \(redactedURL)")
            }
        }
    }
}

private extension URL {
    var removingQueryParameters: URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.query = nil
        components.percentEncodedQuery = nil

        return components.url
    }
}
