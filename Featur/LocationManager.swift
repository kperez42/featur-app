
import CoreLocation
import FirebaseFirestore
// This class updates the latest location and fills in city state country coordinates 
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var city: String?
    @Published var state: String?
    @Published var country: String?
    @Published var coordinates: GeoPoint?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined  // ✅ Add this line

    var isNotDetermined: Bool {
        authorizationStatus == .notDetermined
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus   // ✅ initialize it here
    }

    func requestLocationAccess() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status               // ✅ update published value when changed
        }

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        coordinates = GeoPoint(latitude: location.coordinate.latitude,
                               longitude: location.coordinate.longitude)

        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            guard let placemark = placemarks?.first else { return }
            DispatchQueue.main.async {
                self.city = placemark.locality
                self.state = placemark.administrativeArea
                self.country = placemark.country
            }
        }

        manager.stopUpdatingLocation()
    }
}
