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
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10000
    
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
        
        // 위치 관리 설정 -> 위치 서비스 활성화
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
    }
    
    // 3 앱 내에서의 위치 서비스 권한을 요청
    func checkLocationAuthorization(_ authorizationStatus: CLAuthorizationStatus) {
        switch authorizationStatus {
        case .authorizedWhenInUse:
            print("앱 사용중 허용")
            mapView.showsUserLocation = true // 현위치
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation() // 지도를 움직일때마다 현위치를 업데이트한다.
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
    
    
}

extension MapVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("update")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("change")
    }
}
