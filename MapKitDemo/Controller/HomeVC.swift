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
    lazy var locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureAction))
        self.mapView.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func currentLocBtnAction(_ sender: Any) {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager.startUpdatingLocation()
        }
    }
    //
    //MARK: Get Address
    //
    private func getAddress(coordnates: CLLocationCoordinate2D, complisherHandler:@escaping(String)->()  ) {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordnates.latitude, longitude: coordnates.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler:
                                            { placemarks, error -> Void in
            guard let placeMark = placemarks?.first else { return }
            //guard let locationName = placeMark.location  else {return}
            //guard let street = placeMark.thoroughfare else {return}
            guard let city = placeMark.subAdministrativeArea  else {return}
            guard let zip = placeMark.isoCountryCode else {return}
            guard let country = placeMark.country  else {return}
            let address = "Placemark: \(placeMark.name ?? "No Name"), City: \(city), Country: \(country), Zip Code: \(zip)"
            complisherHandler(address)
        })
    }
    
    @objc func tapGestureAction(sender: UIGestureRecognizer) {
        print("Tapped")
        if mapView.annotations.isEmpty == false {
            for annotation in mapView.annotations {
                self.mapView.removeAnnotation(annotation)
            }
        }
        let locFromTap = sender.location(in: mapView)
        let coordinatesOnMap = mapView.convert(locFromTap, toCoordinateFrom: mapView)
        self.getAddress(coordnates: coordinatesOnMap){ address in
            self.setPinUsingMKPointAnnotation(location: coordinatesOnMap,address: address)
        }
    }
}
//
//MARK: MKMapViewDelegate
//
extension HomeVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnootation")
        annotationView.image = UIImage(named: "Pin")
        annotationView.canShowCallout = true
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Pin selected")
    }
}
//
//MARK: CLLocationManagerDelegate
//
extension HomeVC: CLLocationManagerDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Region change")
//        let northEast = mapView.convert(CGPoint(x: mapView.bounds.width, y: 0), toCoordinateFrom: mapView)
//        let southWest = mapView.convert(CGPoint(x: 0, y: mapView.bounds.height), toCoordinateFrom: mapView)
//        print(southWest)
//        print(northEast)
    }
    //
    //MARK: Get current Location
    //
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapView.setRegion(region, animated: true)
            self.getAddress(coordnates: center) { address in
                self.setPinUsingMKPointAnnotation(location: center, address: address)
            }
        }
    }
}

extension HomeVC {
    //MARK: Set Pin
    //Add pin using MKPlacemark
    func setPinUsingMKPlacemark(location: CLLocationCoordinate2D) {
        let pin = MKPlacemark(coordinate: location)
        let coordinateRegion = MKCoordinateRegion(center: pin.coordinate, latitudinalMeters: 8000, longitudinalMeters: 8000)
        mapView.addAnnotation(pin)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //Add pin using MKPointAnnotation
    func setPinUsingMKPointAnnotation(location: CLLocationCoordinate2D, address: String){
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Title"
        annotation.subtitle = "SubTitle"
        let coordinateRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.addAnnotation(annotation)
        if let vc = storyboard?.instantiateViewController(withIdentifier: "DetailsPopupVC")as? DetailsPopupVC {
            vc.address = address
            self.present(vc, animated: true, completion: nil)
        }
    }
}
