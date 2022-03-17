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
    @IBOutlet weak var titleSubtitleView: UIView!
    @IBOutlet weak var pin: UIImageView!
    @IBOutlet weak var lblPinTitle: UILabel!
    @IBOutlet weak var lblPinSubtitle: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    lazy var locationManager = CLLocationManager()
    lazy var currentLocation = CLLocationCoordinate2D()
    var isSerachBtnClicked = false
    var isPinTapped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
    }
    
    private func config() {
        self.detailView.isHidden = true
        self.titleSubtitleView.isHidden = true
        self.searchBar.isHidden = true
        mapView.delegate = self
        //Map tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureAction))
        self.mapView.addGestureRecognizer(tapGesture)
        //Pin tap gesture
        pin.isUserInteractionEnabled = true
        pin.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pinTapped)))
        
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
    
    @objc private func pinTapped(_ recognizer: UITapGestureRecognizer) {
        self.isPinTapped = !isPinTapped
        if isPinTapped {
            self.titleSubtitleView.isHidden = false
        }else {
            self.titleSubtitleView.isHidden = true
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
            let address = Address(placeMark: placeMark.name ?? "-", country: placeMark.country ?? "-", city: placeMark.subAdministrativeArea ?? "-", zipCode: placeMark.isoCountryCode ?? "-")
            complisherHandler(address)
        })
    }
}
//
//MARK: MKMapViewDelegate
//
extension HomeVC: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        let queue1 = DispatchQueue.global(qos: .background)
        queue1.async {
            self.getAddress(coordnates: center) { address in
                self.detailView.isHidden = false
                self.lblAddress.text = address.fullAddress
                self.lblPinTitle.text = address.placeMark
                self.lblPinSubtitle.text = address.city
            }
        }
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
    func setPinUsingMKPointAnnotation(location: CLLocationCoordinate2D){
        self.detailView.isHidden = false
        if isSerachBtnClicked{
            self.searchBar.isHidden = false
        }else {
            self.searchBar.isHidden = true
        }
        self.lblAddress.isHidden = false
        self.getAddress(coordnates: location) { address in
            self.lblAddress.text = address.fullAddress
            self.lblPinTitle.text = address.placeMark
            self.lblPinSubtitle.text = address.city
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = location
//            annotation.title = address.placeMark
//            annotation.subtitle = address.city
            let coordinateRegion = MKCoordinateRegion(center: location, latitudinalMeters: 800, longitudinalMeters: 800)
            self.mapView.setRegion(coordinateRegion, animated: true)
            //self.mapView.addAnnotation(annotation)
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
