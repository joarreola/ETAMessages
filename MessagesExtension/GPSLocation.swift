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

class GPSLocationAdapter {
    private var packet: Location
    private var mapUpdate = MapUpdate()
    
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
        
        //print("-- GPSLocation -- checkRemote() -- User: \(remoteUser.name)")
 
        let mapUpdate = MapUpdate()

        // MARK: start post-comments

        pollRemoteUser.fetchRemote() {
            
            (packet: Location) in
            
            if packet.latitude == nil {
                //print("-- GPSLocation -- check_remote -- self.pollManager.fetchRemote() - closure -- failed")
                
                result(false)
                
            } else {
                
                //print("-- poll -- self.pollManager.fetchRemote() - closure -- remote latitude: \(String(describing: packet.latitude))")
                //print("-- poll -- self.pollManager.fetchRemote() - closure -- remote longitude: \(String(describing: packet.longitude))")
                
                // update remoteUser Location
                remoteUser.location = packet
                
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        // note coordinates set on display
                        //print("-- GPSLocation -- check_remote -- mapUpdate.addPin()")

                        mapUpdate.addPin(packet: remoteUser.location, mapView: mapView, remove: false)
                    }
                }
                
                // get eta and distance. Returns immediately, closure returns later
                //print("-- GPSLocation -- check_remote -- eta.getEtaDistance()")
 
                eta.getEtaDistance(localPacket: localUser.location, remotePacket: remoteUser.location, mapView: mapView, etaAdapter: eta, display: display)
                
                result(true)
            }
            
        }
 
        // MARK:- end of post-comments
    }
    
    // MARK: moving from locationManager() in MessagesViewcontroller.swift
    
    func handleUploadResult(_ result: Bool, display: UILabel, localUser: Users, remoteUser: Users, mapView: MKMapView, eta: EtaAdapter, pollManager: PollManager) {
        
        if !result {
            
            //print("-- GPSLocation -- handleUploadResult() -- gpsLocation.uploadToIcloud(localUser: localUser) -- Failed")
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    
                    self?.mapUpdate.displayUpdate(display: display, packet: localUser.location, string: "upload to iCloud failed")
                }
            }
            
        } else {
            
            //print("-- GPSLocation -- handleUploadResult() -- gpsLocation.uploadToIcloud(localUser: localUser) -- succeeded")
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    
                    self?.mapUpdate.displayUpdate(display: display, packet: localUser.location, string: "uploaded to iCloud")
                    
                    //print("-- GPSLocation -- handleUploadResult() -- call gpsLocation.check_remote()")
                    
                }
            }
            
            // don't check remote user if polling has net yet been enabled
            if !PollManager.enabledPolling {
                //print("-- handleUploadResult() -- don't check remote user")
                
                return
                
            }
            
            self.checkRemote(pollRemoteUser: pollManager, localUser: localUser, remoteUser: remoteUser, mapView: mapView, eta: eta, display: display) {
                
                (result: Bool) in
                
                //print("-- GPSLocation -- handleUploadResult() -- gpsLocation.checkRemote() closure -- call self.handleCheckRemoteResult(result)")
                
                self.handleCheckRemoteResult(result, display: display, localUser: localUser, remoteUser: remoteUser, eta: eta)
                
            }
        }
    }
    
    func handleCheckRemoteResult(_ result: Bool, display: UILabel, localUser: Users, remoteUser: Users, eta: EtaAdapter) {
        
        if !result {
            
            // failed to fetch RemoteUser's location.
            // Assumed due to Disabled by RemoteUser
            //  - reset poll_entered to 0
            //  - update display
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    
                    self?.mapUpdate.displayUpdate(display: display, packet: localUser.location, string: "remote user location not found", secondString: "tap Poll to restart session")
                }
            }
            
            //            self.poll_entered = 0
            
        } else {
            
            // update display to include remotePacket and eta data
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    
                    self?.mapUpdate.displayUpdate(display: display, localPacket: localUser.location, remotePacket: remoteUser.location, eta: eta)
                    
                }
            }
            
        }
    }
    
    
    // MARK:-

}
