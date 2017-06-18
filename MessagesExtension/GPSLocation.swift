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
    private var packet: Location
    
    init() {
        self.packet = Location()
    }

    /// Upload a location record to iCloud
    /// - Parameters:
    ///     - localUser:
    /// - Returns: Location packet uploading outcome: true or false

    // MARK: start post-comments

    func uploadToIcloud(user: Users, whenDone: @escaping (Bool) -> ()) -> () {
        
        let cloud = CloudAdapter(userName: user.name)

        cloud.upload(user: user) { (result: Bool) in
            
            whenDone(result)
        }
    }

    // MARK:- end post-comments

    /// Attempt to fetch remote-User's record, request eta and distance
    /// if fetched.
    /// - Parameters:
    ///     - pollRemoteUser: A PollManager instance
    ///     - localUser: Users instance for local location coordinates
    ///     - remoteUser: Users instance for remote location coordinates
    ///     - mapView: MKMapView instance for mapView updates
    ///     - eta: EtaAdapter instance to make the getEtaDistance() call
    /// - Returns: Location packet fetching outcome: true or false

    func checkRemote(pollRemoteUser: PollManager, localUser: Users, remoteUser: Users, mapView: MKMapView, eta: EtaAdapter, display: UILabel, result: @escaping (Bool) -> ()) {
        
        print("-- GPSLocation -- checkRemote() -- User: \(remoteUser.name)")
 
        let mapUpdate = MapUpdate()

        // MARK: start post-comments

        pollRemoteUser.fetchRemote() {
            
            (packet: Location) in
            
            if packet.latitude == nil {
                print("-- GPSLocation -- check_remote -- self.pollManager.fetchRemote() - closure -- failed")
                
                result(false)
                
            } else {
                
                print("-- poll -- self.pollManager.fetchRemote() - closure -- remote latitude: \(String(describing: packet.latitude))")
                print("-- poll -- self.pollManager.fetchRemote() - closure -- remote longitude: \(String(describing: packet.longitude))")
                
                // update remoteUser Location
                remoteUser.location = packet
                
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        // note coordinates set on display
                        print("-- GPSLocation -- check_remote -- mapUpdate.addPin()")

                        mapUpdate.addPin(packet: remoteUser.location, mapView: mapView, remove: false)
                    }
                }
                
                // get eta and distance. Returns immediately, closure returns later
                print("-- GPSLocation -- check_remote -- eta.getEtaDistance()")
 
                eta.getEtaDistance(localPacket: localUser.location, remotePacket: remoteUser.location, mapView: mapView, etaAdapter: eta, display: display)
                
                result(true)
            }
            
        }
 
        // MARK:- end of post-comments
    }

}
