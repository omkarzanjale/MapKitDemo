//`
//  ViewController.swift
//  MapKitDemo
//
//  Created by Admin on 11/03/22.
//

import UIKit
import MapKit
import CoreLocation

class HomeVC: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    lazy var locationManager = CLLocationManager()
    lazy var currentLocation = CLLocationCoordinate2D()
    var isSerachBtnClicked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
    }
    
    private func config() {
        self.detailView.isHidden = true
        self.searchBar.isHidden = true
        mapView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureAction))
        self.mapView.addGestureRecognizer(tapGesture)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        if (CLLocationManager.locationServicesEnabled()){
            locationManager.startUpdatingLocation()
        }
    }
    //MARK: Button Actions
    @IBAction private func searchBtnAction() {
        self.searchBar.delegate = self
        self.isSerachBtnClicked = true
        self.detailView.isHidden = false
        self.searchBar.isHidden = false
        if self.lblAddress.text!.isEmpty == false{
            self.lblAddress.isHidden = true
        }else {
            self.lblAddress.isHidden = false
        }
    }
    
    @IBAction func currentLocBtnAction(_ sender: Any) {
        self.setPinUsingMKPointAnnotation(location: self.currentLocation)
    }
    
    @objc func tapGestureAction(sender: UIGestureRecognizer) {
        self.isSerachBtnClicked = false
        let locFromTap = sender.location(in: mapView)
        let coordinatesOnMap = mapView.convert(locFromTap, toCoordinateFrom: mapView)
        self.setPinUsingMKPointAnnotation(location: coordinatesOnMap)
    }
    
    private func removePreviousPin() {
        if mapView.annotations.isEmpty == false {
            for annotation in mapView.annotations {
                self.mapView.removeAnnotation(annotation)
            }
        }
    }
    //
    //MARK: Get Address
    //
    private func getAddress(coordnates: CLLocationCoordinate2D, complisherHandler:@escaping(Address)->()  ) {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordnates.latitude, longitude: coordnates.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler:
                                            { placemarks, error -> Void in
            guard let placeMark = placemarks?.first else { return }
            guard let city = placeMark.subAdministrativeArea  else {return}
            guard let zip = placeMark.isoCountryCode else {return}
            guard let country = placeMark.country  else {return}
            let address = Address(placeMark: placeMark.name ?? "-", country: country, city: city, zipCode: zip)
            complisherHandler(address)
        })
    }
}
//
//MARK: MKMapViewDelegate
//
extension HomeVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        if newState == MKAnnotationView.DragState.ending {
            guard let location = view.annotation?.coordinate else {return}
            self.setPinUsingMKPointAnnotation(location: location)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnootation")
        annotationView.image = UIImage(named: "Pin")
        annotationView.isDraggable = true
        annotationView.canShowCallout = true
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Pin selected")
    }
}

extension HomeVC: CLLocationManagerDelegate {
    //
    //MARK: Get current Location
    //
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            self.currentLocation = center
            
        }
    }
}

extension HomeVC {
    //MARK: Set Pin
    //Add pin using MKPlacemark(Unused)
    func setPinUsingMKPlacemark(location: CLLocationCoordinate2D) {
        let pin = MKPlacemark(coordinate: location)
        let coordinateRegion = MKCoordinateRegion(center: pin.coordinate, latitudinalMeters: 8000, longitudinalMeters: 8000)
        mapView.addAnnotation(pin)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //Add pin using MKPointAnnotation
    func setPinUsingMKPointAnnotation(location: CLLocationCoordinate2D){
        self.detailView.isHidden = false
        if isSerachBtnClicked{
            self.searchBar.isHidden = false
        }else {
            self.searchBar.isHidden = true
        }
        self.lblAddress.isHidden = false
        self.removePreviousPin()
        self.getAddress(coordnates: location) { address in
            self.lblAddress.text = address.fullAddress
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            annotation.title = address.placeMark
            annotation.subtitle = address.city
            let coordinateRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            self.mapView.setRegion(coordinateRegion, animated: true)
            self.mapView.addAnnotation(annotation)
        }
    }
}
//MARK: SearchBar
extension HomeVC: UISearchBarDelegate {
    
    private func searchBaseOn(name: String) {
        let localSearchRequest = MKLocalSearch.Request()
        localSearchRequest.naturalLanguageQuery = name
        let localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { [weak self] response, error in
            guard error == nil else {return}
            guard let response = response else {return}
            let coordinate = CLLocationCoordinate2D(latitude: response.boundingRegion.center.latitude, longitude: response.boundingRegion.center.longitude)
            self?.setPinUsingMKPointAnnotation(location: coordinate)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchedText = searchBar.text else {return}
        searchBar.resignFirstResponder()
        self.searchBaseOn(name: searchedText)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.mapView.isUserInteractionEnabled = false
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        self.mapView.isUserInteractionEnabled = true
        return true
    }
}
