//
//  MapVC.swift
//  MapKitDemo
//
//  Created by 강호성 on 2021/10/21.
//

import UIKit
import MapKit
import CoreLocation // 사용자 위치 처리

class MapVC: UIViewController {
    
    // MARK: - Properites
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10000
    var previousLocation: CLLocation?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationService()
    }
    
    // MARK: - Helper
    
    // 1
    func checkLocationService() {
        let authorizationStatus: CLAuthorizationStatus
        
        if #available(iOS 14, *) { authorizationStatus = locationManager.authorizationStatus }
        else { authorizationStatus = CLLocationManager.authorizationStatus() }
        
        if CLLocationManager.locationServicesEnabled() {
            setupLoactionManager()
            checkLocationAuthorization(authorizationStatus)
        } else {
            
        }
    }
    
    // 2 위치 관리 설정
    func setupLoactionManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 정확도
        mapView.delegate = self
    }
    
    // 3 앱 내에서의 위치 서비스 권한을 요청
    func checkLocationAuthorization(_ authorizationStatus: CLAuthorizationStatus) {
        switch authorizationStatus {
        case .authorizedWhenInUse:
            print("앱 사용중 허용")
            mapView.showsUserLocation = true // 현위치
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation() // 지도를 움직일때마다 현위치를 업데이트한다.
            previousLocation = getPinCenterLocation(for: mapView)
        case .denied:
            print("권한 요청 거부")
        case .notDetermined:
            print("결정되지 않음 -> 권한 요청")
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("제한")
        case .authorizedAlways:
            print("항상 허용")
        default:
            print("GPS: Default")
        }
    }
    
    // 4 사용자 위치 확대
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // MARK: - Pin Helper
    
    // 핀의 중심 위치
    func getPinCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
}

// MARK: - CLLocationManagerDelegate

extension MapVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization(status)
    }
}
 

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getPinCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        let locale = Locale(identifier: "Ko-kr")
        
        guard let previousLocation = self.previousLocation else { return }
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center, preferredLocale: locale) { placemark, error in
            guard error == nil, let place = placemark?.first else {
                print("주소 설정 불가능")
                return
            }
            
            // UI 업데이트마다 메인 스레드로 다시 이동
            DispatchQueue.main.async {
                let address = "\(place.administrativeArea ?? "") \(place.locality ?? "") \(place.subThoroughfare ?? "") \(place.thoroughfare ?? "")"
                self.addressLabel.text = address
            }
        }
    }
}
