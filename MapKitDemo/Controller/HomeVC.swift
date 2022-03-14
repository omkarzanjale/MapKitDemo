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
    
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addressView.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureAction))
        self.mapView.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func closeViewBtnAction(_ sender: Any) {
        self.addressView.isHidden = true
    }
    
    private func getAddress(coordnates: CLLocationCoordinate2D) {
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
            DispatchQueue.main.async {
                self.lblAddress.text = "Placemark: \(placeMark.name ?? "No Name"), City: \(city), Country: \(country), Zip Code: \(zip)"
            }
        })
    }
    
    @objc func tapGestureAction(sender: UIGestureRecognizer) {
        self.addressView.isHidden = false
       
        if mapView.annotations.isEmpty == false {
            self.mapView.removeAnnotation(mapView.annotations[0])
        }
        print("Tapped")
        let locFromTap = sender.location(in: mapView)
        let coordinatesOnMap = mapView.convert(locFromTap, toCoordinateFrom: mapView)
        self.getAddress(coordnates: coordinatesOnMap)
        setPinUsingMKPointAnnotation(location: coordinatesOnMap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let northEast = mapView.convert(CGPoint(x: mapView.bounds.width, y: 0), toCoordinateFrom: mapView)
        let southWest = mapView.convert(CGPoint(x: 0, y: mapView.bounds.height), toCoordinateFrom: mapView)
        print(southWest)
        print(northEast)
    }
}

extension HomeVC {
    //Add pin using MKPlacemark
    func setPinUsingMKPlacemark(location: CLLocationCoordinate2D) {
        let pin = MKPlacemark(coordinate: location)
        let coordinateRegion = MKCoordinateRegion(center: pin.coordinate, latitudinalMeters: 8000, longitudinalMeters: 8000)
        mapView.addAnnotation(pin)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //Add pin using MKPointAnnotation
    func setPinUsingMKPointAnnotation(location: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Title"
        annotation.subtitle = "SubTitle"
        let coordinateRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.addAnnotation(annotation)
    }
}
