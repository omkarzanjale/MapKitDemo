//`
//  ViewController.swift
//  MapKitDemo
//
//  Created by Admin on 11/03/22.
//

import UIKit
import MapKit
import CoreLocation
import GooglePlaces
class HomeVC: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var titleSubtitleView: UIView!
    @IBOutlet weak var pin: UIImageView!
    @IBOutlet weak var lblPinTitle: UILabel!
    @IBOutlet weak var lblPinSubtitle: UILabel!
    lazy var locationManager = CLLocationManager()
    lazy var currentLocation = CLLocationCoordinate2D()
    lazy var autoCompleteController = GMSAutocompleteViewController()
    var isSerachBtnClicked = false
    var isPinTapped = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
    }
    
    private func config() {
        self.titleSubtitleView.isHidden = true
        mapView.delegate = self
        if ((lblAddress.text?.isEmpty) != nil){
            self.lblAddress.isHidden = true
        }
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
    //
    //MARK: Search Btn
    //
    @IBAction func searchBtnAction(_ sender: Any) {
        autoCompleteController.delegate = self
        let fields = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) | UInt(GMSPlaceField.placeID.rawValue))
        autoCompleteController.placeFields = fields
        
        let filter = GMSAutocompleteFilter()
        filter.type = .noFilter
        autoCompleteController.autocompleteFilter = filter
        
        present(autoCompleteController, animated: true)
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
                self.lblAddress.text = address.fullAddress
                self.lblPinTitle.text = address.name
                self.lblPinSubtitle.text = address.city
            }
        }
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
        self.lblAddress.isHidden = false
        self.getAddress(coordnates: location) { address in
            self.lblAddress.text = address.fullAddress
            self.lblPinTitle.text = address.name
            self.lblPinSubtitle.text = address.city
            let coordinateRegion = MKCoordinateRegion(center: location, latitudinalMeters: 800, longitudinalMeters: 800)
            self.mapView.setRegion(coordinateRegion, animated: true)
        }
    }
    
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
}
//
//MARK: GMSAutocompleteViewControllerDelegate
//
extension HomeVC: GMSAutocompleteViewControllerDelegate{
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        self.searchBaseOn(name: place.name ?? "")
        dismiss(animated: true)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true)
    }
}
