//
//  DetailsPopupVC.swift
//  MapKitDemo
//
//  Created by Admin on 15/03/22.
//

import UIKit

class DetailsPopupVC: UIViewController {

    @IBOutlet weak var lblAddress: UILabel!
    var address = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lblAddress.text = address
    }

}
