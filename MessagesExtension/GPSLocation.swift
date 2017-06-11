//
//  GPSLocation.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 6/7/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

/// Helper for CLLocation framework's locationManager() callback
///
/// updateUserCoordinates(Users:, Location)
/// uploadToIcloud(Users)
/// checkRemote(PollManager, Users, Users, MKMapView, EtaAdapter) -> Bool

class GPSLocation {
    private var lmPacket: Location
    
    init() {
        self.lmPacket = Location()
        self.lmPacket.setLatitude(latitude: 0.0)
        self.lmPacket.setLongitude(longitude: 0.0)
    }

    /// Update location data in User instance, and local lmPacket copy
    /// - Parameters:
    ///     - localUser:
    ///     - lmPacket:
    
    func updateUserCoordinates(localUser: Users, lmPacket: Location) {
        // stuff User's Location structure and update lmPacket
        
        print("-- GPSLocation -- updateLocalCoordinates() -- User: \(localUser.getName())")
        
        localUser.location.setLatitude(latitude: lmPacket.latitude)
        
        localUser.location.setLongitude(longitude: lmPacket.longitude)
        
        self.lmPacket.setLatitude(latitude: lmPacket.latitude)
        
        self.lmPacket.setLongitude(longitude: lmPacket.longitude)

    }
    
    /// Upload a location record to iCloud
    /// - Parameters:
    ///     - localUser:
    /// - Returns: Location packet uploading outcome: true or false

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

    /// Attempt to fetch remote-User's record, request eta and distance
    /// if fetched.
    /// - Parameters:
    ///     - pollRemoteUser: A PollManager instance
    ///     - localUser: Users instance for local location coordinates
    ///     - remoteUser: Users instance for remote location coordinates
    ///     - mapView: MKMapView instance for mapView updates
    ///     - eta: EtaAdapter instance to make the getEtaDistance() call
    /// - Returns: Location packet fetching outcome: true or false

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
