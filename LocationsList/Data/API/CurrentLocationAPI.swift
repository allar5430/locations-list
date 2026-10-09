import CoreLocation
import Foundation
import os

protocol CurrentLocationGetting: Sendable {
    func getCurrentCoordinate() async throws(CurrentLocationError) -> PlaceCoordinate
}

@MainActor
final class CurrentLocationAPI: NSObject, CurrentLocationGetting, @preconcurrency CLLocationManagerDelegate {
    private let manager: CLLocationManager
    private lazy var logger = Logger.make(for: .api(.currentLocation))
    private var requestTask: Task<PlaceCoordinate, Error>?
    private var continuation: CheckedContinuation<PlaceCoordinate, Error>?

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        self.manager.delegate = self
    }

    func getCurrentCoordinate() async throws(CurrentLocationError) -> PlaceCoordinate {
        if let requestTask {
            logger.info("Awaiting existing current location request")
            return try await value(from: requestTask)
        }

        logger.info("Starting current location request")

        let requestTask: Task<PlaceCoordinate, Error> = Task { @MainActor [weak self] in
            guard let self else {
                throw CurrentLocationError.locationUnavailable
            }

            return try await self.requestCurrentCoordinate()
        }
        self.requestTask = requestTask
        defer { self.requestTask = nil }

        return try await value(from: requestTask)
    }

    private func value(from task: Task<PlaceCoordinate, Error>) async throws(CurrentLocationError) -> PlaceCoordinate {
        do {
            return try await task.value
        } catch let error as CurrentLocationError {
            throw error
        } catch {
            throw .locationUnavailable
        }
    }

    private func requestCurrentCoordinate() async throws -> PlaceCoordinate {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PlaceCoordinate, Error>) in
            self.continuation = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .denied, .restricted:
                complete(throwing: .permissionDenied)
            @unknown default:
                complete(throwing: .permissionDenied)
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            complete(throwing: .permissionDenied)
        case .notDetermined:
            break
        @unknown default:
            complete(throwing: .permissionDenied)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            complete(throwing: .locationUnavailable)
            return
        }

        complete(returning: PlaceCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        complete(throwing: .locationUnavailable)
    }

    private func complete(returning coordinate: PlaceCoordinate) {
        guard let continuation else { return }
        self.continuation = nil

        logger.info("Current location request succeeded")
        continuation.resume(returning: coordinate)
    }

    private func complete(throwing error: CurrentLocationError) {
        guard let continuation else { return }
        self.continuation = nil

        logger.error("Current location request failed: \(error.description)")
        continuation.resume(throwing: error)
    }
}

enum CurrentLocationError: Error, Equatable, Sendable, CustomStringConvertible {
    case permissionDenied
    case locationUnavailable

    var description: String {
        switch self {
        case .permissionDenied:
            return "Current location permission denied"
        case .locationUnavailable:
            return "Current location unavailable"
        }
    }
}
