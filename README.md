### MapKitDemo 


### import

```swift
import MapKit
import CoreLocation
```

1️⃣. 기본 제공되는 지도를 사용하기 위한 ***MapKit***

2️⃣. ***CoreLocation***

- 지리적 위치 서비스를 제공
- CoreLocation이 실행되면 승인 요청 alert 메세지
- 기기의 위치데이터를 받기 전 반드시 승인 요청을 확인한다.
- ***CLLocationManagerDelegate*** 프로토콜은 location manager 객체에 연관된 이벤트를 파악할 때 사용

**`CLLocationManagerDelegate`**

```swift
extension MapVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
}
```

**`CLLocationManager`**

- CLLocationManager 클래스는 위치 관련 이벤트를 앱에 시작하고, 중지하는데 사용하는 오브젝트이다.

먼저 CLLocationManager 클래스의 인스턴스 `locationManager` 를 만들어준다.

```swift
let locationManager = CLLocationManager()
```

---

### GPS 권한 요청

- `authorizationStatus` 버전에 따른 처리
- **CLLocationManager.locationServicesEnabled()** → 위치정보를 사용할 수 있도록 설정에서 허용되어있는지 확인

```swift
func checkLocationService() {
   let authorizationStatus: CLAuthorizationStatus
        
   if #available(iOS 14, *) { authorizationStatus = locationManager.authorizationStatus }
   else { authorizationStatus = CLLocationManager.authorizationStatus() }
        
    if CLLocationManager.locationServicesEnabled() {
         1️⃣ setupLoactionManager() // 위치 관리 설정
         2️⃣ checkLocationAuthorization(authorizationStatus) // 앱 내 위치 서비스 권한 요청
    } else {
            
    }
}
```

위치 서비스가 **활성화**되었다면 (`CLLocationManager.locationServicesEnabled()`)

1️⃣  locationManager 객체에 delegate를 연결해주고, 정확도를 설정한다.

```swift
func setupLoactionManager() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest // 정확도
}
```

**[참고]** 위치 정확도

![best](https://user-images.githubusercontent.com/74236080/138255556-9a54fcee-7c81-4309-96d1-593e30032e00.png)




2️⃣  앱 내에서의 위치 서비스 권한을 요청한다.

- 권한을 허용하면 (`.authorizedWhenInUse`), 사용자의 현재 위치를 띄우고, 위치에 해당하는 지역을 확대한다.
- 아직 권한 설정을 하지않았다면 (`.notDetermined`), 권한을 요청한다.
`locationManager.requestWhenInUseAuthorization()`

```swift
func checkLocationAuthorization(_ authorizationStatus: CLAuthorizationStatus) {
     switch authorizationStatus {
     case .authorizedWhenInUse:
         print("앱 사용중 허용")
         mapView.showsUserLocation = true // 현위치
         centerViewOnUserLocation()

     case .denied:
         print("권한 요청 거부") 
	// 권한 승인 알림 

     case .notDetermined: -> 앱을 처음 실행했을 때 해당 케이스에 들어온다.
         print("결정되지 않음 -> 권한 요청")
         locationManager.requestWhenInUseAuthorization()

     case .restricted:
         print("제한")
	// 설정탭으로 이동

     case .authorizedAlways:
         print("항상 허용")

     default:
         print("GPS: Default")
     }
 }
```

- 위치서비스 권한이 허용 되었다면, 사용자 위치 확대한다.

```swift
func centerViewOnUserLocation() {
    if let location = locationManager.location?.coordinate {
        let region = MKCoordinateRegion.init(center: location, 
																						latitudinalMeters: regionInMeters, 
																						longitudinalMeters: regionInMeters)
        // mapView에 지정한 지역을 확대
	mapView.setRegion(region, animated: true)
    }
}
```

<img src = "https://user-images.githubusercontent.com/74236080/138254877-9fdaae50-69e6-4b1f-9c0a-d4b233a942b7.png" width="40%" height="40%">


---

- 현위치의 주소를 Label에 업데이트 해야한다고 하면, 권한이 허용됐을 때 지도를 움직일때마다 현위치를 업데이트한다.

```swift
case .authorizedWhenInUse:
     print("앱 사용중 허용")
     mapView.showsUserLocation = true
     centerViewOnUserLocation()
     locationManager.startUpdatingLocation()
```

이제 여기서 위치 업데이트를 하므로, 사용자의 위치가 업데이트될 때마다 ***CLLocationManagerDelegate***에서  `didUpdateLocations` 를 실행한다.

`[CLLocation]` 배열을 반환할 때마다 **배열의 마지막 위치**를 계속 업데이트한다.

```swift
func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
     guard let location = locations.last else { return }
     let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
     let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
     mapView.setRegion(region, animated: true)      
}
```

1. `guard문`으로 위치가 없을 때를 고려해서 **location**을 생성한다.
2. 현재 위치가 mapView에서 중앙 어디에 위치해있는지 알기 위해 **center** 생성
3. **region** → 사용자의 위치를 중앙에 배치
4. mapView에 지정한 지역을 확대

이 과정을 통해 **regionInMeters (1,000)** 반경 (**region**) 안에서 업데이트되는 위치를 알 수 있다. 

- ***CLLocationManagerDelegate*** 에서 또 다른 메서드인 `didChangeAuthorization` 는 권한 부여가 변경될 때마다 위치 권한 부여를 다시 확인한다.

```swift
func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		checkLocationAuthorization(status)
}

```

---

### 해당 위치 주소 가져오기

- 화면을 움직일 때, 현재 주소를 표시하기 위해 핀을 추가해서 지도의 중앙을 확인한다.
- 그리고 해당 핀의 주소를 띄워줄 라벨도 아래에 만들어준다.


<img src = "https://user-images.githubusercontent.com/74236080/138255014-28f5ee07-3564-43da-904a-f78ef619618a.png" width="40%" height="40%">

https://user-images.githubusercontent.com/74236080/138255188-cb8cb044-f12a-4015-a23e-13d357db7ec3.mov


- 핀의 위치를 확인하기 위해 `MKMapViewDelegate` 를 설정해야 한다.

`regionDidChangeAnimated` 메서드에서는 지도화면의 중심을 계속 추적하고, 변경될 때마다 해당 좌표를 사용해서 위치를 Label에 적용한다.

```swift
extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
    }
}
```

해당 delegate 도 위치 서비스가 활성화 됐을 때, 사용할 수 있도록 `setupLoactionManager` 메서드에 연결해준다.

```swift
func setupLoactionManager() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest // 정확도
    
    mapView.delegate = self
}
```

그럼 계속해서 변경되는 핀의 중심을 확인하기 위한 메서드를 만들어준다.

```swift
func getPinCenterLocation(for mapView: MKMapView) -> CLLocation {
    let latitude = mapView.centerCoordinate.latitude
    let longitude = mapView.centerCoordinate.longitude
        
    return CLLocation(latitude: latitude, longitude: longitude)
}
```

`getPinCenterLocation` 메서드를 통해 핀의 위치가 변경될 때마다, 항상 **center**라는 변수에 지도의 중심을 갖게된다.

```swift
extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
	let center = getPinCenterLocation(for: mapView)
		
		...
```

---

**그럼 이제 핀의 중심 좌표(위도, 경도)를 가진 `center`를 가지고 주소를 어떻게 가져와야할까**

![geo](https://user-images.githubusercontent.com/74236080/138255941-a99fa6c2-645c-4c0c-b4d4-ff2376c6b22f.png)


> **CLGeocoder** → 지리적 좌표와 장소 이름 간의 변환을 위한 인터페이스
> 

위도/경도 등의 위치 좌표를 이용해 현재 위치의 주소를 얻는 것을 **Reverse Geocode** 라고 부른다. 

iOS에는 **CLGeocoder**라는 클래스를 통해 주소를 좌표로, 좌표를 주소로 변경할 수 있는 기능을 제공한다.

```swift
extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getPinCenterLocation(for: mapView)

				let geoCoder = CLGeocoder()
        let locale = Locale(identifier: "Ko-kr") // 한국 주소
        
        geoCoder.reverseGeocodeLocation(center, preferredLocale: locale) { placemark, error in
            guard error == nil, let place = placemark?.first else {
                print("주소 설정 불가능")
                return
            }
        }
    }
}
```

1. 먼저 이전 위치를 추적하기 위해 변수를 생성한다. *처음에는 위치가 0이기 때문에 옵셔널로 선언한다.*

```swift
var previousLocation: CLLocation?
```

2. 그리고 앱 내에서의 위치 서비스 권한을 허용했을 때, **위치의 좌표값을 저장**한다.

```swift
case .authorizedWhenInUse:
    print("앱 사용중 허용")
    mapView.showsUserLocation = true
    centerViewOnUserLocation()
    locationManager.startUpdatingLocation()

    previousLocation = getPinCenterLocation(for: mapView)
```

3. MKMapViewDelegate 로 돌아와서 위치 좌표를 이용해 현재 위치의 주소(**center**)를 얻기 전에 아래와 같이 처리해준다.
    
    
    - **움직임이 50m 이하인 경우에는 위치 정보를 호출하지 않도록 설정**
    
    - 50m 보다 더 움직이게 되면 이전 위치(previousLocation)에 현재의 위치(center)로 업데이트
    
    - 그리고 해당 위치의 좌표를 주소로 변경
    
```swift
extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
       let center = getPinCenterLocation(for: mapView)
    				
    	...
    
        guard let previousLocation = self.previousLocation else { return }      
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
    					
        geoCoder.reverseGeocodeLocation(center, preferredLocale: locale) { placemark, error in
   
   	...
    }
}
```
    

4. **Reverse Geocode**가 끝나면, addressLabel에 주소를 넣는다.

- ***DispatchQueue.main.async***
    
    Reverse Geocode 과정을 비동기식으로 수행하고, UI를 업데이트할 때마다 메인 스레드로 다시 이동해서 처리
    

```swift
extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getPinCenterLocation(for: mapView)
				
				...

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
```

https://user-images.githubusercontent.com/74236080/138255374-df45bef9-6505-47a8-a338-f4e38fbf09b2.mov



