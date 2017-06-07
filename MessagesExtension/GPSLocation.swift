//
//  GPSLocation.swift
//  ETAMessages
//
//  Created by taiyo on 6/7/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
//import CloudKit

class GPSLocation {
    var lmPacket: Location
    
    init() {
        self.lmPacket = Location()
        self.lmPacket.setLatitude(latitude: 0.0)
        self.lmPacket.setLongitude(longitude: 0.0)
    }

    
    func updateUserCoordinates(localUser: Users, lmPacket: Location) {
        // stuff User's Location structure and update lmPacket
        
        print("-- GPSLocation -- updateLocalCoordinates() -- User: \(localUser.getName())")
        
        localUser.location.setLatitude(latitude: lmPacket.latitude)
        
        localUser.location.setLongitude(longitude: lmPacket.longitude)
        
        self.lmPacket.setLatitude(latitude: lmPacket.latitude)
        
        self.lmPacket.setLongitude(longitude: lmPacket.longitude)

    }
    
    func uploadToIcloud(localUser: Users) -> Bool {
        //upload to iCloud if enabled_uploading set in IBAction enable()
        
        print("-- GPSLocation -- uploadToIcloud() -- User: \(localUser.getName())")
        
        let cloud = CloudAdapter(userName: localUser.getName())
                
        // upload coordinates
        let cloudRet = cloud.upload(packet: localUser.location)
                
        if cloudRet == false
        {
            print("-- GPSLocation -- uploadToIcloud() -- cloud.upload() -- Failed")
        }
        else
        {
            print("-- GPSLocation -- uploadToIcloud() -- cloud.upload() -- succeeded")
        }
        
        return cloudRet
    
    }

    func checkRemote(pollRemoteUser: PollManager, localUser: Users, remoteUser: Users,
                     mapView: MKMapView, eta: EtaAdapter) -> Bool {
        // extract location and eta data for remoteUser
        
        print("-- GPSLocation -- checkRemote() -- User: \(remoteUser.getName())")
 
        var latitude: CLLocationDegrees
        var longitude: CLLocationDegrees
        let mapUpdate = MapUpdate()
        let fetchRet = pollRemoteUser.fetchRemote()
 
        if (fetchRet.latitude == nil) {
 
            return false
        }

        (latitude, longitude) = fetchRet as! (CLLocationDegrees, CLLocationDegrees)
 
        remoteUser.location.setLatitude(latitude: latitude)
        remoteUser.location.setLongitude(longitude: longitude)
 
        print("-- check_remote -- mapUpdate.addPin()")
 
        mapUpdate.addPin(packet: remoteUser.location, mapView: mapView, remove: false)
 
        print("-- check_remote -- eta.getEtaDistance()")
 
        eta.getEtaDistance(localPacket: localUser.location, remotePacket: remoteUser.location)
 
        return true
    }

}
