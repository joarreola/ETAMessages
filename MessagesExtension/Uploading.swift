//
//  Uploading.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 6/4/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CoreLocation
import CloudKit
import UIKit

/// Manage uploading of location packets.
/// Update display to provide status to user.
///
/// uploadLocation(Location)
/// updateMap(UILabel, Location)
/// updateMap(UILabel, Location, String)
/// enableUploading()
/// disableUploading()

class UploadingManager {
    private var latitude: CLLocationDegrees = 0.0
    private var longitude: CLLocationDegrees = 0.0
    private var mapUdate: MapUpdate
    private var cloud: CloudAdapter
    static var enabledUploading: Bool = false

    init(name: String) {
        self.mapUdate = MapUpdate()
        self.cloud  = CloudAdapter(userName: name)
    }

    /// Upload location packet to iCloud
    /// - Parameters:
    ///     - packet: location packet to upload to iCloud
    /// - Returns: upload outcome: true or false
    
/// MARK: post-comments

    func uploadLocation(user: Users, whenDone: @escaping (Bool) -> ()) -> () {

        cloud.upload(user: user) { (result: Bool) in

            whenDone(result)
        }
    }

// MARK:-
    
    /// Update display with local location coordinates
    /// - Parameters:
    ///     - display: UILabel instance display
    ///     - packet: location coordinates to display

    func updateMap(display: UILabel, packet: Location) {
        //print("--Uploading -- updateMap(display: UILabel, packet: Location)")

        // display locPacket
        mapUdate.displayUpdate(display: display, packet: packet)

    }
    
    /// Update display with local location coordinates and a string message
    /// - Parameters:
    ///     - display: UILabel instance display
    ///     - packet: location coordinates to display
    ///     - string: message to display

    func updateMap(display: UILabel, packet: Location, string: String) {
        //print("--Uploading -- updateMap(display: UILabel, packet: Location, string; String)")
        
        // display locPacket
        mapUdate.displayUpdate(display: display, packet: packet, string: string)
        
    }

    /// Note that uploading has been enabled after a tap on the Enable button

    func enableUploading() {
        //print("--Uploading -- enableUploading")

        // this allows for uploading of coordinates on LocalUser location changes
        UploadingManager.enabledUploading = true
    }
    
    /// Note that uploading has been disabled after a tap on the Disable button

    func disableUploading() {
        //print("--Uploading -- disableUploading")
        
        // remove record
        self.cloud.deleteRecord()

        // this allows for uploading of coordinates on LocalUser location changes
        UploadingManager.enabledUploading = false
    }

}
