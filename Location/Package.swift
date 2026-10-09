// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Location",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "LocationDomain", targets: ["LocationDomain"]),
        .library(name: "LocationKit", targets: ["LocationKit"]),
        .library(name: "LocationUI", targets: ["LocationUI"])
    ],
    targets: [
        .target(
            name: "LocationDomain",
            packageAccess: true,
            swiftSettings: [.defaultIsolation(nil)]
        ),
        .target(
            name: "LocationKit",
            dependencies: ["LocationDomain"],
            packageAccess: true,
            swiftSettings: [.defaultIsolation(nil)]
        ),
        .target(
            name: "LocationUI",
            dependencies: ["LocationDomain"],
            resources: [.process("Resources")],
            packageAccess: true,
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "LocationDomainTests",
            dependencies: ["LocationDomain"],
            packageAccess: true,
            swiftSettings: [.defaultIsolation(nil)]
        ),
        .testTarget(
            name: "LocationKitTests",
            dependencies: ["LocationKit", "LocationDomain"],
            packageAccess: true,
            swiftSettings: [.defaultIsolation(nil)]
        ),
        .testTarget(
            name: "LocationUITests",
            dependencies: ["LocationUI", "LocationDomain"],
            packageAccess: true,
            swiftSettings: [.defaultIsolation(nil)]
        )
    ]
)
