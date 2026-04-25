
import Foundation
import CoreLocation
import MapKit


protocol LocationServiceProtocol: AnyObject {
    /// Request always-on location permission (required for geofencing).
    func requestPermission() async -> CLAuthorizationStatus

    /// Register a geofence region around a POI.
    func registerGeofence(identifier: String, coordinate: CLLocationCoordinate2D,
                           radius: CLLocationDistance) throws

    /// Remove a previously registered geofence.
    func removeGeofence(identifier: String)

    /// Remove all registered geofences.
    func removeAllGeofences()

    /// Search for nearby points of interest by keyword.
    func searchNearby(keyword: String,
                       region: MKCoordinateRegion) async throws -> [MKMapItem]
}


final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    // MARK: - Permission

    func requestPermission() async -> CLAuthorizationStatus {
        manager.requestAlwaysAuthorization()
        // Wait briefly for the delegate callback
        try? await Task.sleep(nanoseconds: 500_000_000)
        return manager.authorizationStatus
    }

    // MARK: - Geofencing

    func registerGeofence(identifier: String,
                           coordinate: CLLocationCoordinate2D,
                           radius: CLLocationDistance) throws {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            throw ServiceError.permissionDenied
        }
        let region = CLCircularRegion(center: coordinate,
                                       radius: min(radius, 400),   // iOS max = ~400 m accurate
                                       identifier: identifier)
        region.notifyOnExit = true
        region.notifyOnEntry = false
        manager.startMonitoring(for: region)
    }

    func removeGeofence(identifier: String) {
        manager.monitoredRegions
            .filter { $0.identifier == identifier }
            .forEach { manager.stopMonitoring(for: $0) }
    }

    func removeAllGeofences() {
        manager.monitoredRegions.forEach { manager.stopMonitoring(for: $0) }
    }

    // MARK: - Nearby search

    func searchNearby(keyword: String,
                       region: MKCoordinateRegion) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = keyword
        request.region = region

        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager,
                          didExitRegion region: CLRegion) {
        // Post a local notification reminding the user to upload a receipt
        let content = UNMutableNotificationContent()
        content.title = "Did you get a receipt?"
        content.body  = "You just left \(region.identifier). Snap your receipt now!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let req = UNNotificationRequest(identifier: "rs.geo.\(region.identifier)",
                                         content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}

import UserNotifications
