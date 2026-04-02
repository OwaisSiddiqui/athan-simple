import Foundation
import CoreLocation
import SwiftUI
import Combine
import MapKit
import GeoToolbox

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        #if os(iOS)
        locationManager.requestWhenInUseAuthorization()
        #else
        // On macOS, first check if location services are enabled
        guard CLLocationManager.locationServicesEnabled() else {
            DispatchQueue.main.async {
                self.errorMessage = "Location services are disabled. Please enable them in System Preferences > Security & Privacy > Privacy > Location Services."
            }
            return
        }
        
        // Request appropriate authorization based on current status
        switch authorizationStatus {
        case .notDetermined:
            // On macOS, we need to request authorization
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.errorMessage = "Location access is required to calculate accurate prayer times. Please enable location access in System Preferences > Security & Privacy > Privacy > Location Services and restart the app."
            }
        case .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            locationManager.requestAlwaysAuthorization()
        }
        #endif
    }
    
    func startLocationUpdates() {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        #else
        // On macOS, check if location services are enabled and we have permission
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services are disabled. Please enable them in System Preferences > Security & Privacy > Privacy > Location Services."
            return
        }
        
        guard authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        #endif
        
        isLoading = true
        errorMessage = nil
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }

    func reverseGeocodeLocation(_ location: CLLocation) async {
        // Use the older CLGeocoder API for compatibility with iOS 17.0
        let geocoder = CLGeocoder()
        
        do {
            // Perform the geocoding request
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            // Update the UI on the main thread
            await MainActor.run {
                self.isLoading = false
                
                guard let placemark = placemarks.first else {
                    self.errorMessage = "No location details found"
                    return
                }
                
                // Use the standard CLPlacemark properties
                let city = placemark.locality ?? "Unknown City"
                let state = placemark.administrativeArea ?? "Unknown State"
                
                self.city = city
                self.state = state
            }
        } catch {
            // Handle any errors
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to get location details: \(error.localizedDescription)"
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.location = location
            // Save location for widget
            WidgetDataManager.shared.saveLocation(location)
            Task {
                await self.reverseGeocodeLocation(location)
            }
        }
        
        stopLocationUpdates()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            // Handle specific macOS sandbox restriction error
            if let nsError = error as NSError?, nsError.domain == "NSCocoaErrorDomain" && nsError.code == 4099 {
                self.errorMessage = "Location access is restricted. Please ensure the app has location permissions in System Preferences > Security & Privacy > Privacy > Location Services and restart the app."
            } else {
                self.errorMessage = "Location error: \(error.localizedDescription)"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            #if os(iOS)
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startLocationUpdates()
            } else if status == .denied || status == .restricted {
                self.errorMessage = "Location access is required to calculate accurate prayer times. Please enable location access in Settings."
            }
            #else
            if status == .authorizedAlways {
                self.startLocationUpdates()
            } else if status == .denied || status == .restricted {
                self.errorMessage = "Location access is required to calculate accurate prayer times. Please enable location access in System Preferences > Security & Privacy > Privacy > Location Services."
            } else if status == .notDetermined {
                // On macOS, if status is not determined, try requesting permission again
                self.requestLocationPermission()
            }
            #endif
        }
    }
}
