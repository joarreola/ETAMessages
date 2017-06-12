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
    private var etaOriginal: TimeInterval
    private let cloudRemote: CloudAdapter
    
    init(remoteUserName: String) {
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

    func fetchRemote() -> (latitude: CLLocationDegrees?, longitude: CLLocationDegrees?) {
        print("-- Poll -- fetchRemote")
        
        return cloudRemote.fetchRecord()
        
    }

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
        print("-- Poll -- pollRemote")

        var rlat: CLLocationDegrees?
        var rlong: CLLocationDegrees?
        
        // initialize to current local and remote postions
        self.myLocalPacket = Location()
        self.myLocalPacket.setLatitude(latitude: localUser.location.latitude)
        self.myLocalPacket.setLongitude(longitude: localUser.location.longitude)

        self.myRemotePacket = Location()
        self.myRemotePacket.setLatitude(latitude: remotePacket.latitude)
        self.myRemotePacket.setLongitude(longitude: remotePacket.longitude)

        let mapUpdate = MapUpdate();
        
        /**
         *
         * Below code runs in a separate thread
         *
         */
        DispatchQueue.global(qos: .background).async {
    
            print("\n===============================================================\n")
            print("-- Poll -- pollRemote -- in queque.addOperation()")
            print("\n===============================================================\n")
    
            // etaOriginal
            self.etaOriginal = eta.getEta()!
            print("-- Poll -- pollRemote -- self.etaOriginal: \(self.etaOriginal)")
    
            // MARK:
                // FIXME: Add loop-terminating code
            print("-- Poll -- pollRemote -- into while{}")
            var initialEta = eta.getEta()

            /**
             *
             * While loop terminated when Double(self.myEta!) < 50.0
             *
             */
            while true {
    
                // check pointer
                self.myEta = eta.loadPointer()
                self.myDistance = eta.getDistance()
                
                print("-- Poll -- pollRemote -- self.myEta: \(self.myEta!) self.myDistance: \(String(describing: self.myDistance!))")
    
                // selffetchRemote()
                print("-- Poll -- pollRemote -- pre self.fetchRemote()")
    
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
                    if localUser.location.latitude != self.myLocalPacket.latitude ||
                        localUser.location.longitude != self.myLocalPacket.longitude
                    {
                        self.myLocalPacket.setLatitude(latitude: localUser.location.latitude)
                        self.myLocalPacket.setLongitude(longitude: localUser.location.longitude)

                    }
                }
                
                if self.myEta !=  initialEta {
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
                    
                    initialEta = self.myEta!
                }
                
                if  self.myEta != self.etaOriginal {
                    
                    self.etaNotification(display: display)
                }
                
                // ETA == has-arrived
                if Double(self.myEta!) < 50.0 {
                    print("-- Poll -- pollRemote -- stopping pollRemote")

                    break
                }
                
                // FIXME: switch to NSTime
                print("-- Poll -- pollRemote -- sleep 2...")
                sleep(2)
    
            } // end of while{}
            // MARK:-

        } // end of DispatchQueue.global(qos: .background).async

    } // end of pollRemote()


    /// Request local notifications based on ETA data
    /// - Parameters:
    ///     - display: UILabel instance display

    func etaNotification(display: UILabel) {
        print("-- Poll - etaNotification -- etaOriginal: \(self.etaOriginal) myEta: \(self.myEta!)")
        
        let mapUpdate = MapUpdate()

        switch self.myEta! {
        //case etaOriginal:
        //
        //    print("Poll - etaNotification -- myEta == etaOriginal")
            
        case (self.etaOriginal / 4) * 3:

            print("/n=====================================================================/n")
            print("-- Poll - etaNotification -- myEta == etaOriginal/4 * 3")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket,
                                    remotePacket: self.myRemotePacket,
                                    string: "eta:\t\t\((self.myEta!)) sec",
                                    secondString: "3/4ths there")
            }
    
        case (self.etaOriginal / 4) * 2:
            
            print("/n=====================================================================/n")
            print("-- Poll - etaNotification -- myEta == etaOriginal/4 * 2")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket,
                                    remotePacket: self.myRemotePacket,
                                    string: "eta:\t\t\((self.myEta!)) sec",
                                    secondString: "Half-way there")
            }
            
        case (self.etaOriginal / 4) * 1:
            
            print("/n=====================================================================/n")
            print("-- Poll - etaNotification -- myEta == etaOriginal/4 * 1")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket,
                                    remotePacket: self.myRemotePacket,
                                    string: "eta:\t\t\((self.myEta!)) sec",
                                    secondString: "1/4th there")
            }
            
        case 0.0...50.0:

            print("/n=====================================================================/n")
            print("-- Poll - etaNotification -- myEta == 0")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket,
                                        remotePacket: self.myRemotePacket,
                                        string: "eta:\t\t\((self.myEta!)) sec",
                                        secondString: "\(self.remoteUserName) Has arrived")
            }
            
        default:
            
            print("Poll - etaNotification -- default")
        }
    }

}


