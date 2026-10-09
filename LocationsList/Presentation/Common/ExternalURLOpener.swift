import Foundation
import SwiftUI

@MainActor protocol ExternalURLOpening {
    func open(_ url: URL)
}

struct SwiftUIExternalURLOpener: ExternalURLOpening {
    private let openURL: OpenURLAction

    init(openURL: OpenURLAction) {
        self.openURL = openURL
    }

    func open(_ url: URL) {
        openURL(url)
    }
}
