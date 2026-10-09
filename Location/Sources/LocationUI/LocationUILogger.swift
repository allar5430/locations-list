import os

extension Logger {
    static let locationUIRouter = Logger(
        subsystem: "com.example.PlacesApp",
        category: "router"
    )
    static let locationUIAddCustomLocation = Logger(
        subsystem: "com.example.PlacesApp",
        category: "viewModel.addCustomLocation"
    )
}
