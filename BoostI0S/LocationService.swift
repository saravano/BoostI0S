//
//  LocationServiceType.swift
//  BoostI0S
//
//  Created by Sara on 12/17/25.
//


import Foundation
import CoreLocation

protocol LocationServiceType {
    func requestCurrentLocation(completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void)
}

final class LocationService: NSObject, LocationServiceType, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    private var completion: ((Result<CLLocationCoordinate2D, Error>) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestCurrentLocation(completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        self.completion = completion
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            completion(.failure(CLError(.denied)))
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        @unknown default:
            completion(.failure(CLError(.locationUnknown)))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }
        completion?(.success(coord))
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()  // Now call after authorization granted
        case .restricted, .denied:
            completion?(.failure(CLError.denied as! Error))
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            completion?(.failure(CLError.locationUnknown as! Error))
        }
    }
}
