//
//  Poll.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit
import MapKit

/// Poll iCloud for remote User's location record.
/// Request local notifications based on ETA data
///
/// fetchRemote(CLLocationDegrees?, CLLocationDegrees?)
/// pollRemote(Users, Location, MKMapView, EtaAdapter, UILabel)
/// etaNotification(UILabel)

class PollManager {
    private var latitude: CLLocationDegrees?
    private var longitude: CLLocationDegrees?
    private var remoteFound: Bool = false
    private let remoteUserName: String
    private var myLocalPacket: Location
    private var myRemotePacket: Location
    private var myEta: TimeInterval?
    private var myDistance: Double?
    private var etaOriginal: TimeInterval?
    private let cloudRemote: CloudAdapter
    static  var enabledPolling: Bool = false
    private let hasArrivedEta: Double = 20.0
    
    init(remoteUserName: String) {
        print("-- PollManager -- init()")

        self.latitude = 0.0
        self.longitude = 0.0
        self.remoteUserName = remoteUserName
        self.myEta = 0.0
        self.etaOriginal = 0.0
        self.myDistance = 0.0
        
        self.cloudRemote  = CloudAdapter(userName: remoteUserName)
        self.myLocalPacket = Location()
        self.myRemotePacket = Location()
        
    }

    /// Fetch remoteUser's location record from iCloud
    /// - Returns: A tuple of latitude and longitude coordinates
// MARK: pre-comments
    /*
    func fetchRemote() -> (latitude: CLLocationDegrees?, longitude: CLLocationDegrees?) {
        print("-- PollManager -- fetchRemote")
        
        return cloudRemote.fetchRecord()
        
    }
    */
// MARK:-
    
// MARK: post comments

    func fetchRemote(whenDone: @escaping (Location) -> ()) -> () {
        print("-- PollManager -- fetchRemote(whenDone: @escaping (Location) -> ()) -> ()")
        
        cloudRemote.fetchRecord() {
            
            (packet: Location) in

            if packet.latitude == nil {
                print("-- PollManager -- fetchRemote(whenDone: @escaping (Location) -> ()) -> () -- cloudRemote.fetchRecord() -- closure -- failed")

                whenDone(packet)
                
            } else {
                print("-- PollManager -- fetchRemote(whenDone: @escaping (Location) -> ()) -> () -- cloudRemote.fetchRecord() -- closure -- latitude: \(String(describing: packet.latitude)) -- longitude: \(String(describing: packet.longitude))")
                
                print("-- PollManager -- fetchRemote(whenDone: @escaping (Location) -> ()) -> () -- cloudRemote.fetchRecord() -- closure -- call: whenDone(Location)")

                whenDone(packet)
            }
        }
    }

// MARK:-

    /// Poll iCloud for remote User's location record.
    /// while-loop runs in a background DispatchQueue.global thread.
    /// MapView updates are done in the DispatchQueue.main thread.
    /// Call etaNotification() to make local notifications posting
    ///     requests based on ETA data.
    /// - Parameters:
    ///     - localUser: local User instance
    ///     - remotePacket: remote location coordinates
    ///     - mapView: instance of MKMapView to re-center mapView
    ///     - eta: EtaAdapter instance with eta and distance properties
    ///     - display: UILabel instance display
    
    func pollRemote(localUser: Users, remotePacket: Location, mapView: MKMapView,
                    eta: EtaAdapter, display: UILabel) {
        print("-- PollManager -- pollRemote()")

        //var rlat: CLLocationDegrees?
        //var rlong: CLLocationDegrees?
        
        // initialize to current local and remote postions
        self.myLocalPacket = Location()
        self.myLocalPacket.setLatitude(latitude: localUser.location.latitude!)
        self.myLocalPacket.setLongitude(longitude: localUser.location.longitude!)

        self.myRemotePacket = Location()
        self.myRemotePacket.setLatitude(latitude: remotePacket.latitude!)
        self.myRemotePacket.setLongitude(longitude: remotePacket.longitude!)

        let mapUpdate = MapUpdate();
        
        // MARK: start of DispatchQueue.global(qos: .background).async

        /**
         *
         * Below code runs in a separate thread
         *
         */
        DispatchQueue.global(qos: .background).async {
    
            print("\n===============================================================")
            print("-- PollManager -- pollRemote() -- in queque.addOperation()")
            print("=================================================================")
    
            // etaOriginal
            self.etaOriginal = eta.getEta()
            print("-- PollManager -- pollRemote() -- DispatchQueue.global -- self.etaOriginal: \(String(describing: self.etaOriginal))")


            // MARK: start of while-loop
            
            /**
             *
             * While loop terminated when Double(self.myEta!) < 20.0, or
             * setting PollManager.enabledPolling to false in @IBAction disable()
             *
             */
            print("-- PollManager -- pollRemote() -- DispatchQueue.global -- into while{}")

            while PollManager.enabledPolling {
    
                // check pointer
                self.myEta = eta.loadPointer()
                self.myDistance = eta.getDistance()
                
                print("-- PollManager -- pollRemote() -- DispatchQueue.global -- self.myEta: \(String(describing: self.myEta)) self.myDistance: \(String(describing: self.myDistance))")
    
                // self.fetchRemote()
                print("-- PollManager -- pollRemote() -- DispatchQueue.global -- pre self.fetchRemote()")
        
                // MARK: start of pre-comments

                /*
                (rlat, rlong) = self.fetchRemote()

                (rlat == nil) ? (self.remoteFound = false) : (self.remoteFound = true)


                if self.remoteFound {
                    print("-- Poll -- pollRemote -- self.cloudRemote.fetchRecord() -- rlat: \(String(describing: rlat!))")
                    print("-- Poll -- pollRemote -- self.cloudRemote.fetchRecord() -- rlong: \(String(describing: rlong!))")
                } else {
                    print("-- Poll -- pollRemote -- self.remoteFound: \(self.remoteFound)")
                }
            
                print("-- Poll -- pollRemote -- localUser.location.latitude: \(localUser.location.latitude)")
                print("-- Poll -- pollRemote -- localUser.location.longitude: \(localUser.location.longitude)")

                if self.remoteFound &&
                    (rlat != self.myRemotePacket.latitude ||
                     rlong != self.myRemotePacket.longitude ||
                     localUser.location.latitude != self.myLocalPacket.latitude ||
                     localUser.location.longitude != self.myLocalPacket.longitude
                    )
                {
                    // update myRemotePacket and myLocalPacket
                    self.myRemotePacket.setLatitude(latitude: rlat!)
                    self.myRemotePacket.setLongitude(longitude: rlong!)
                    
                    // do here?
                    self.myLocalPacket.setLatitude(latitude: localUser.location.latitude)
                    self.myLocalPacket.setLongitude(longitude: localUser.location.longitude)
                
                
                    // get eta and distance. Returns immediately, closure returns later
                    eta.getEtaDistance(localPacket: self.myLocalPacket,
                                       remotePacket: self.myRemotePacket)
                    
                    
                    // or do here?
                    /*
                    if localUser.location.latitude != self.myLocalPacket.latitude ||
                        localUser.location.longitude != self.myLocalPacket.longitude
                    {
                        self.myLocalPacket.setLatitude(latitude: localUser.location.latitude)
                        self.myLocalPacket.setLongitude(longitude: localUser.location.longitude)

                    }
                    */
//                }
                
                //if self.myEta !=  initialEta {
                    // do UI updates in the main thread
                    
                    DispatchQueue.main.async { [weak self ] in
                        
                        if self != nil {
                            
                            // refreshMapView here vs. in eta.getEtaDistance()
                            print("-- Poll -- pollRemote -- call mapUpdate.refreshMapView()")
                    
                            mapUpdate.addPin(packet: (self?.myRemotePacket)!,
                                             mapView: mapView, remove: false)

                            mapUpdate.refreshMapView(localPacket: (self?.myLocalPacket)!,
                                        remotePacket: (self?.myRemotePacket)!,
                                        mapView: mapView, eta: eta)
                            
                            mapUpdate.displayUpdate(display: display,
                                            localPacket: self!.myLocalPacket,
                                            remotePacket: self!.myRemotePacket,
                                            eta: eta)
                        }

                    }
                    
                    //initialEta = self.myEta!
                //}
                } // include DispatchQueue.main.async in diff check
                */
                // MARK:- end of pre-comments
                
                // MARK: start of post-comments

                print("-- PollManager -- pollRemote() -- DispatchQueue.global -- self.myEta: \(self.myEta!)")
                print("-- PollManager -- pollRemote() -- DispatchQueue.global -- etaOriginal: \(self.etaOriginal!)")

                if  self.myEta! != self.etaOriginal! {
                    print("\n===============================================================")
                    print("-- PollManager -- pollRemote() -- DispatchQueue.global -- calling self.etaNotification(display: display)")
                    print("===============================================================\n")
                    
                    self.etaNotification(display: display)
                }

                self.fetchRemote() {
                    
                    (packet: Location) in
                    
                    if packet.latitude == nil {
                        print("-- PollManager -- pollRemote() -- DispatchQueue.global -- self.fetchRemote() -- closure -- returned nil")
                        
                        // UI updates on main thread
                        DispatchQueue.main.async { [weak self ] in
                            
                            if self != nil {
                                
                                // display localUserPacket
                                mapUpdate.displayUpdate(display: (display), packet: packet, string: "fetchRemote failed")
                                
                            }
                        }

                        return
                        
                    }
                    
                    if packet.latitude != self.myRemotePacket.latitude ||
                        packet.longitude != self.myRemotePacket.longitude ||
                        localUser.location.latitude != self.myLocalPacket.latitude ||
                        localUser.location.longitude != self.myLocalPacket.longitude
                    {
                        print("\n===============================================================")
                        print("-- PollManager -- pollRemote() -- DispatchQueue.global -- LOCATION CHANGED")
                        print("===============================================================\n")
            
                        print("-- PollManager -- pollRemote() -- DispatchQueue.global -- self.fetchRemote() -- closure -- remote latitude: \(String(describing: packet.latitude))")
                        print("-- PollManager -- pollRemote() -- DispatchQueue.global -- self.fetchRemote() -- closure -- remote longitude: \(String(describing: packet.longitude))")
                        
                        // update myRemotePacket and myLocalPacket
                        self.myRemotePacket.setLatitude(latitude: packet.latitude!)
                        self.myRemotePacket.setLongitude(longitude: packet.longitude!)
                        
                        self.myLocalPacket.setLatitude(latitude: localUser.location.latitude!)
                        self.myLocalPacket.setLongitude(longitude: localUser.location.longitude!)


                        // get eta and distance. Returns immediately, closure returns later
                        print("-- PollManager -- pollRemote() -- DispatchQueue.global -- self.fetchRemote() -- closure -- call: eta.getEtaDistance...")
                        
                        eta.getEtaDistance (localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, mapView: mapView, etaAdapter: eta, display: display)
                        
                        // UI updates on main thread
                        DispatchQueue.main.async { [weak self ] in
                            
                            if self != nil {
                               
                                // refreshMapView here vs. in eta.getEtaDistance()
                                print("-- PollManager -- pollRemote() -- DispatchQueue.main.async -- self.fetchRemote() -- call mapUpdate.refreshMapView()")
                                
                                mapUpdate.addPin(packet: (self?.myRemotePacket)!,
                                                 mapView: mapView, remove: false)
                                
                                mapUpdate.refreshMapView(localPacket: (self?.myLocalPacket)!,
                                                         remotePacket: (self?.myRemotePacket)!,
                                                         mapView: mapView, eta: eta)
                                
                                mapUpdate.displayUpdate(display: display,
                                                        localPacket: self!.myLocalPacket,
                                                        remotePacket: self!.myRemotePacket,
                                                        eta: eta)
                            }
                        }
                    } // end of location compare
                } // end of self.fetchRemote()
   
                // MARK:- end of post-comments

                // ETA == has-arrived, break out of while-loop
                if Double(self.myEta!) <= self.hasArrivedEta {
                    print("\n===========================================================")
                    print("-- PollManager -- pollRemote() -- DispatchQueue.global -- STOPPING POLLREMOTE")
                    print("===============================================================\n")

                    break
                }
    
                // FIXME: switch to NSTime or iCloud notification
                print("\n===========================================================")
                print("-- PollManager -- pollRemote() -- DispatchQueue.global -- sleep 2...")
                print("===============================================================\n")

                sleep(2)
    
            }
            
            // MARK:- end of while-loop

        }
        
        // MARK:- end of DispatchQueue.global(qos: .background).async

    }

    /// Request local notifications based on ETA data
    /// - Parameters:
    ///     - display: UILabel instance display

    func etaNotification(display: UILabel) {
        print("-- PollManager -- etaNotification() -- etaOriginal: \(String(describing: self.etaOriginal)) myEta: \(self.myEta!)")
        
        let mapUpdate = MapUpdate()

        switch self.myEta! {
        case (self.etaOriginal! / 4) * 3:

            print("/n=====================================================================/n")
            print("-- PollManager -- etaNotification -- myEta == etaOriginal/4 * 3")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket,
                                    remotePacket: self.myRemotePacket,
                                    string: "eta:\t\t\((self.myEta!)) sec",
                                    secondString: "3/4ths there")
            }
    
        case (self.etaOriginal! / 4) * 2:
            
            print("/n=====================================================================/n")
            print("-- PollManager -- etaNotification() -- myEta == etaOriginal/4 * 2")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket,
                                    remotePacket: self.myRemotePacket,
                                    string: "eta:\t\t\((self.myEta!)) sec",
                                    secondString: "Half-way there")
            }
            
        case (self.etaOriginal! / 4) * 1:
            
            print("/n=====================================================================/n")
            print("-- PollManager -- etaNotification() -- myEta == etaOriginal/4 * 1")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket,
                                    remotePacket: self.myRemotePacket,
                                    string: "eta:\t\t\((self.myEta!)) sec",
                                    secondString: "1/4th there")
            }
            
        case 0.0...self.hasArrivedEta:

            print("/n=====================================================================/n")
            print("-- PollManager -- etaNotification() -- myEta == 0")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket,
                                        remotePacket: self.myRemotePacket,
                                        string: "eta:\t\t\((self.myEta!)) sec",
                                        secondString: "\(self.remoteUserName) Has arrived")
            }
            
        default:
            
            print("-- PollManager -- etaNotification -- default")
        }
    }
    
    /// Note that polling has been enabled
    
    func enablePolling() {
        print("-- PollManager -- enablePolling")
        
        PollManager.enabledPolling = true
    }

    /// Note that polling has been disabled
    
    func disablePolling() {
        print("-- PollManager -- disablePolling")
        
        PollManager.enabledPolling = false
    }

}


