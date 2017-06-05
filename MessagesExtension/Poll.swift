//
//  Poll.swift
//  ETAMessages
//
//  Created by taiyo on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit
import MapKit

class Poll {
    private var latitude: CLLocationDegrees?
    private var longitude: CLLocationDegrees?
    private var remoteFound: Bool = false
    private let remoteUser: String
    private let locationRecordID: CKRecordID
    private let locationRecord: CKRecord
    private let myContainer: CKContainer
    private var myPacket: Location
    private var myEta: TimeInterval?
    private var myDistance: Double?
    private var etaOriginal: TimeInterval
    
    init(remoteUser: String) {
        self.latitude = 0.0
        self.longitude = 0.0
        self.remoteUser = remoteUser
        self.myEta = 0.0
        self.etaOriginal = 0.0
        self.myDistance = 0.0
        
        self.locationRecordID = CKRecordID(recordName: remoteUser)
        print("-- Poll -- init -- set CKRecordID: \(locationRecordID)")
        
        self.locationRecord = CKRecord(recordType: "Location",
                                       recordID: locationRecordID)
        print("-- Poll -- init -- locationRecord: \(locationRecord)")

        // private container
        self.myContainer = CKContainer(identifier: "iCloud.edu.ucsc.ETAMessages")
        print("-- Poll -- init -- set CKContainer: iCloud.edu.ucsc.ETAMessages")
        
        myPacket = Location()
        
    }
    
    func fetchRemote() -> (latitude: CLLocationDegrees?, longitude: CLLocationDegrees?) {
        print("-- Poll -- fetchRemote")

        // start semaphore block to synchronize completion handler
        let sem = DispatchSemaphore(value: 0)

        self.myContainer.privateCloudDatabase.fetch(withRecordID: self.locationRecordID) {
            (record, error) in
            if let error = error {
                print("-- Poll -- fetchRemote -- Error: \(self.locationRecordID): \(error)")
            
                self.remoteFound = false
        
                sem.signal()
    
                return
                
            } else {
                self.latitude = record?["latitude"] as? CLLocationDegrees
                self.longitude = record?["longitude"] as? CLLocationDegrees

                self.remoteFound = true
                
                sem.signal()

                return
            }
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture)
        
        if(!self.remoteFound) {
            return (nil, nil)
        }
        
        return(self.latitude, self.longitude)
    }
    
    func pollRemote(packet: Location, mapView: MKMapView, eta: Eta, display: UILabel) {
        print("-- Poll -- pollRemote")

        var rlat: CLLocationDegrees?
        var rlong: CLLocationDegrees?
        self.myPacket = packet
        let mapUpdate = MapUpdate();
        
        // below code runs in a separate thread

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

            while true {
    
                // check pointer
                self.myEta = eta.loadPointer()
                self.myDistance = eta.getDistance()
                
                print("-- Poll -- pollRemote -- self.myEta: \(self.myEta!) self.myDistance: \(String(describing: self.myDistance!))")
    
                // fetchRemote()
                print("-- Poll -- pollRemote -- pre self.fetchRemote()")
    
                (rlat, rlong) = self.fetchRemote()

                if self.remoteFound {
                    print("-- Poll -- pollRemote -- self.fetchRemote() -- rlat: \(String(describing: rlat))")
                    print("-- Poll -- pollRemote -- self.fetchRemote() -- rlong: \(String(describing: rlong))")
                } else {
                    print("-- Poll -- pollRemote -- self.remoteFound: \(self.remoteFound)")
                }
            
                //print("-- Poll -- pollRemote -- packet.latitude: \(packet.latitude)")
                //print("-- Poll -- pollRemote -- packet.longitude: \(packet.longitude)")

                if self.remoteFound &&
                    (rlat != self.myPacket.remoteLatitude ||
                     rlong != self.myPacket.remoteLongitude
                     //packet.latitude != self.myPacket.latitude ||
                     //packet.longitude != self.myPacket.longitude
                    )
                {
                    // update myPacket
                    self.myPacket.setRemoteLatitude(latitude: rlat!)
                    self.myPacket.setRemoteLongitude(longitude: rlong!)
                
                
                    // get eta and distance. Returns immediately, closure returns later
                    eta.getEtaDistance(packet: self.myPacket)
                    
                    if packet.latitude != self.myPacket.latitude ||
                        packet.longitude != self.myPacket.longitude
                    {
                        self.myPacket.setLatitude(latitude: packet.latitude)
                        self.myPacket.setLongitude(longitude: packet.longitude)

                    }
                }
                
                if self.myEta !=  initialEta {
                    // do UI updates in the main thread
                    
                    DispatchQueue.main.async { [weak self ] in
                        
                        if self != nil {
                            
                            // refreshMapView here vs. in eta.getEtaDistance()
                            print("-- Poll -- pollRemote -- call mapUpdate.refreshMapView()")
                    
                            mapUpdate.addPin(packet: (self?.myPacket)!, mapView: mapView, remove: false)

                            mapUpdate.refreshMapView(packet: (self?.myPacket)!, mapView: mapView, eta: eta)
                        
                            var string = [String]()
                            print("-- Poll -- pollRemote -- string size: \(string.count)")
                            string.append("local:\t\t( \(String(describing: self?.myPacket.latitude)),\n\t\t\(String(describing: self?.myPacket.longitude)) )\n")
                            string.append("remote:\t( \(String(describing: self?.myPacket.remoteLatitude)),\n\t\t\(String(describing: self?.myPacket.remoteLongitude)) )\n")
                            string.append("eta:\t\t\(String(describing: (self?.myEta!))) sec\n")
                            string.append("distance:\t\(String(describing: (self?.myDistance!))) ft")
                        
                            mapUpdate.displayUpdate(display: display, stringArray: string)
                        }

                    }
                    
                    initialEta = self.myEta!
                }
                
                if  self.myEta != self.etaOriginal {
                    
                    self.etaNotification(etaOriginal: self.etaOriginal, myEta: self.myEta!, display: display)
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


    func etaNotification(etaOriginal: TimeInterval, myEta: TimeInterval, display: UILabel) {
        print("Poll - etaNotification -- etaOriginal: \(etaOriginal) myEta: \(myEta)")
        
        let mapUpdate = MapUpdate()

        switch myEta {
        case etaOriginal:
            
            print("Poll - etaNotification -- myEta == etaOriginal")
            
        case (etaOriginal / 4) * 3:

            print("Poll - etaNotification -- myEta == etaOriginal/4 * 3")
            /*
            display.text = ""
            display.text =
                "local:\t\t( \(myPacket.latitude),\n\t\t\t\(myPacket.longitude) )\n" +
                "remote:\t( \(myPacket.remoteLatitude),\n\t\t\t\(myPacket.remoteLongitude) )\n" +
                "eta:\t\t\((myEta)) sec\n" +
                "3/4's notification"
            */
        case (etaOriginal / 4) * 2:
            
            print("Poll - etaNotification -- myEta == etaOriginal/4 * 2")
            
        case (etaOriginal / 4) * 1:
            
            print("Poll - etaNotification -- myEta == etaOriginal/4 * 1")
            
        case 0.0...50.0:

            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                print("Poll - etaNotification -- myEta == 0")
                var string = [String]()
                string.append("local:\t\t( \(self.myPacket.latitude),\n\t\t\t\(self.myPacket.longitude) )\n")
                string.append("remote:\t( \(self.myPacket.remoteLatitude),\n\t\t\t\(self.myPacket.remoteLongitude) )\n")
                string.append("eta:\t\t\((myEta)) sec\n")
                string.append("Oscar Has arrived")
                
                mapUpdate.displayUpdate(display: display, stringArray: string)
    
            }
            
        default:
            
            print("Poll - etaNotification -- default")
        }

    }

}


