
import UIKit
import MapKit
import CoreLocation

protocol LocationSelectionDelegate: AnyObject {
    func didSelectLocation(_ location: String, coordinate: CLLocationCoordinate2D)
}

class MapKitViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
    
    var mapView: MKMapView!
    var searchBar: UISearchBar!
    var locationManager: CLLocationManager!
    weak var delegate: LocationSelectionDelegate?
    
    var destinationCoordinate: CLLocationCoordinate2D?
    var selectedLocation: String?
    var coordinate: CLLocationCoordinate2D?
    var currentAnnotation: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        mapView = MKMapView(frame: self.view.bounds)
        self.view.addSubview(mapView)
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search for a location"
        searchBar.sizeToFit()
        self.view.addSubview(searchBar)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40).isActive = true
        searchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(mapTapped(_:)))
        mapView.addGestureRecognizer(tapGestureRecognizer)
        
        if let selectedLocation = selectedLocation, let coordinate = coordinate {
            addAnnotation(at: coordinate, with: selectedLocation)
            mapView.setCenter(coordinate, animated: true)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.first {
            mapView.setCenter(userLocation.coordinate, animated: true)
            
            if let destinationCoordinate = destinationCoordinate {
                calculateDirections(from: userLocation.coordinate, to: destinationCoordinate)
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        performSearch(query: searchText)
    }
    
    
    func performSearch(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        
        search.start { [weak self] response, error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                print("Error searching for location: \(error)")
                return
            }
            
            guard let response = response else { return }
            
            if let firstItem = response.mapItems.first {
                let coordinate = firstItem.placemark.coordinate
                strongSelf.mapView.setCenter(coordinate, animated: true)
                
                
                if let currentAnnotation = strongSelf.currentAnnotation {
                    strongSelf.mapView.removeAnnotation(currentAnnotation)
                }
                
                strongSelf.addAnnotation(at: coordinate, with: firstItem.name ?? "Unknown Location")
                
                
                strongSelf.destinationCoordinate = coordinate
                
                
                if let locationName = firstItem.name {
                    strongSelf.delegate?.didSelectLocation(locationName, coordinate: coordinate)
                    
                    if let userLocation = strongSelf.locationManager.location {
                        strongSelf.calculateDirections(from: userLocation.coordinate, to: coordinate)
                    }
                }
            }
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let annotation = view.annotation, let title = annotation.title ?? "" {
            delegate?.didSelectLocation(title, coordinate: annotation.coordinate)
            
            
            if let userLocation = locationManager.location {
                calculateDirections(from: userLocation.coordinate, to: annotation.coordinate)
            }
        }
    }
    
    
    func calculateDirections(from userLocation: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let userPlaceMark = MKPlacemark(coordinate: userLocation)
        let destinationPlaceMark = MKPlacemark(coordinate: destination)
        
        let userMapItem = MKMapItem(placemark: userPlaceMark)
        let destinationMapItem = MKMapItem(placemark: destinationPlaceMark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = userMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] response, error in
            if let error = error {
                print("Error calculating directions: \(error)")
                return
            }
            
            guard let response = response, let route = response.routes.first else { return }
            
            
            self?.mapView.addOverlay(route.polyline)
            self?.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    
    func addAnnotation(at coordinate: CLLocationCoordinate2D, with title: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapView.addAnnotation(annotation)
        currentAnnotation = annotation
    }
    
    @objc func mapTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let tappedCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        
        if let currentAnnotation = currentAnnotation {
            mapView.removeAnnotation(currentAnnotation)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = tappedCoordinate
        mapView.addAnnotation(annotation)

        currentAnnotation = annotation
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: tappedCoordinate.latitude, longitude: tappedCoordinate.longitude)) { [weak self] (placemarks, error) in
            guard let strongSelf = self else { return }
            
            if let error = error {
                print("Error during reverse geocoding: \(error)")
                return
            }
            
            if let placemark = placemarks?.first {
                
                let locationName = placemark.name ?? "Unknown Location"
                
                annotation.title = locationName
                
                strongSelf.delegate?.didSelectLocation(locationName, coordinate: tappedCoordinate)
            }
        }
    }
}

