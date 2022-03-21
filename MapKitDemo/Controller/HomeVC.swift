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
    
    var resultSearchController:UISearchController? = nil
    var locationSearchBar: UISearchBar?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
        searchBarConfig()
    }
    
    private func searchBarConfig() {
        let locationSearchTable = storyboard?.instantiateViewController(withIdentifier: "LocationSearchTable") as? LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController!.searchResultsUpdater = locationSearchTable
        locationSearchBar = resultSearchController!.searchBar
        locationSearchBar?.sizeToFit()
        locationSearchBar?.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        locationSearchTable?.mapView = mapView
        locationSearchTable?.delegate = self
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
        self.lblAddress.isHidden = false
        self.getAddress(coordnates: location) { address in
            self.lblAddress.text = address.fullAddress
            self.lblPinTitle.text = address.name
            self.lblPinSubtitle.text = address.city
            let coordinateRegion = MKCoordinateRegion(center: location, latitudinalMeters: 800, longitudinalMeters: 800)
            self.mapView.setRegion(coordinateRegion, animated: true)
        }
    }
}

extension HomeVC: HandleSearchProtocol {
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
    func searchedData(data: String) {
        self.searchBaseOn(name: data)
        self.locationSearchBar?.text = data
    }
}
