//
//  Uploading.swift
//  ETAMessages
//
//  Created by taiyo on 6/4/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CoreLocation
import CloudKit
import UIKit

class UploadingManager {
    var latitude: CLLocationDegrees = 0.0
    var longitude: CLLocationDegrees = 0.0
    var mapUdate: MapUpdate
    var cloud: CloudAdapter
    static var enabledUploading: Bool = false

    init(name: String) {
        self.mapUdate = MapUpdate()
        self.cloud  = CloudAdapter(userName: name)
    }

    func uploadLocation(packet: Location) -> Bool {
        print("--Uploading -- uploadLocation")

        let cloudRet = cloud.upload(packet: packet)

        if (cloudRet == false) {
            print("--Uploading -- uploadLocation -- cloud.upload(packet) returned nil.")
        
        }

        return cloudRet
    }

    func updateMap(display: UILabel, packet: Location) {
        print("--Uploading -- updateMap(display: UILabel, packet: Location)")

        // display locPacket
        mapUdate.displayUpdate(display: display, packet: packet)

    }
    
    func updateMap(display: UILabel, packet: Location, string: String) {
        print("--Uploading -- updateMap(display: UILabel, packet: Location, string; String)")
        
        // display locPacket
        mapUdate.displayUpdate(display: display, packet: packet, string: string)
        
    }

    func enableUploading() {
        print("--Uploading -- enableUploading")

        // this allows for uploading of coordinates on LocalUser location changes
        UploadingManager.enabledUploading = true
    }
    
    func disableUploading() {
        print("--Uploading -- disableUploading")
        
        // this allows for uploading of coordinates on LocalUser location changes
        UploadingManager.enabledUploading = false
    }

}
