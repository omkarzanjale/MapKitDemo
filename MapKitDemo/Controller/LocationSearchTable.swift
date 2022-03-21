//
//  LocationSearchTable.swift
//  MapKitDemo
//
//  Created by Admin on 21/03/22.
//

import UIKit
import MapKit

protocol HandleSearchProtocol: AnyObject {
    func searchedData(data: String)
}

class LocationSearchTable : UITableViewController {
    var matchingItems:[MKMapItem] = []
    var mapView: MKMapView? = nil
    weak var delegate: HandleSearchProtocol?
}

extension LocationSearchTable : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
                let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {return}
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}

extension LocationSearchTable{
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let selectedItem = matchingItems[indexPath.row]
        let resultCell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        resultCell?.textLabel?.text = selectedItem.name
        resultCell?.detailTextLabel?.text = ""
        return resultCell!
    }
}
extension LocationSearchTable{
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedData = matchingItems[indexPath.row].name else {return}
        delegate?.searchedData(data: selectedData)
        self.dismiss(animated: true)
    }
}
