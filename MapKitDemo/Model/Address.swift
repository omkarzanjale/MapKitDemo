//
//  Address.swift
//  MapKitDemo
//
//  Created by Admin on 16/03/22.
//

import Foundation

struct Address {
    let placeMark: String
    let country: String
    let city: String
    let zipCode: String
    let fullAddress: String
    init(placeMark: String, country: String, city: String, zipCode: String) {
        self.placeMark = placeMark
        self.country = country
        self.city = city
        self.zipCode = zipCode
        self.fullAddress = "Placemark: \(placeMark), City: \(city), Country: \(country), Zip Code: \(zipCode)"
    }
}
