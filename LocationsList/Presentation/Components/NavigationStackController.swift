import SwiftUI

@MainActor protocol NavigationStackControlling: AnyObject, Observable {
    associatedtype SheetRoute: Identifiable

    var path: NavigationPath { get set }
    var presentedSheet: SheetRoute? { get set }
}

@MainActor protocol OpenURLConfiguring: AnyObject {
    func configure(openURL: OpenURLAction)
}

struct NavigationStackController<Router: NavigationStackControlling, Content: View, SheetContent: View>: View {
    @Environment(\.openURL) private var openURL
    @Bindable private var router: Router

    private let content: () -> Content
    private let sheetContent: (Router.SheetRoute) -> SheetContent

    init(
        router: Router,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder sheetContent: @escaping (Router.SheetRoute) -> SheetContent
    ) {
        self.router = router
        self.content = content
        self.sheetContent = sheetContent
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            content()
                .onAppear {
                    configureRouterIfNeeded()
                }
                .sheet(item: $router.presentedSheet) { route in
                    sheetContent(route)
                }
        }
    }

    private func configureRouterIfNeeded() {
        guard let router = router as? OpenURLConfiguring else { return }
        router.configure(openURL: openURL)
    }
}
