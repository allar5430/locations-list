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
    private var requestTask: Task<Result<PlaceCoordinate, CurrentLocationError>, Never>?
    private var continuation: CheckedContinuation<Result<PlaceCoordinate, CurrentLocationError>, Never>?

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        self.manager.delegate = self
    }

    func getCurrentCoordinate() async throws(CurrentLocationError) -> PlaceCoordinate {
        if let requestTask {
            logger.info("Awaiting existing current location request")
            return try await requestTask.value.get()
        }

        logger.info("Starting current location request")

        let requestTask: Task<Result<PlaceCoordinate, CurrentLocationError>, Never> = Task { @MainActor [weak self] in
            guard let self else {
                return .failure(CurrentLocationError.locationUnavailable)
            }

            return await self.requestCurrentCoordinate()
        }
        self.requestTask = requestTask
        defer { self.requestTask = nil }

        return try await requestTask.value.get()
    }

    private func requestCurrentCoordinate() async -> Result<PlaceCoordinate, CurrentLocationError> {
        await withCheckedContinuation { (continuation: CheckedContinuation<Result<PlaceCoordinate, CurrentLocationError>, Never>) in
            self.continuation = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .denied, .restricted:
                complete(with: .failure(CurrentLocationError.permissionDenied))
            @unknown default:
                complete(with: .failure(CurrentLocationError.permissionDenied))
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            complete(with: .failure(CurrentLocationError.permissionDenied))
        case .notDetermined:
            break
        @unknown default:
            complete(with: .failure(CurrentLocationError.permissionDenied))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            complete(with: .failure(CurrentLocationError.locationUnavailable))
            return
        }

        complete(with: .success(PlaceCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        complete(with: .failure(.locationUnavailable))
    }

    private func complete(with result: Result<PlaceCoordinate, CurrentLocationError>) {
        guard let continuation else { return }
        self.continuation = nil

        switch result {
        case .success:
            logger.info("Current location request succeeded")
        case .failure(let error):
            logger.error("Current location request failed: \(error.description)")
        }

        continuation.resume(returning: result)
    }
}

enum CurrentLocationError: Error, Equatable, CustomStringConvertible {
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
