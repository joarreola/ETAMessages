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
    
    init(remoteUser: String) {
        self.latitude = 0.0
        self.longitude = 0.0
        self.remoteUser = remoteUser
        
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
        
        // start semaphore block to synchronize completion handler
        let sem = DispatchSemaphore(value: 0)

        self.myContainer.privateCloudDatabase.fetch(withRecordID: self.locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- Poll -- fetchRemote -- Error: \(self.locationRecordID): \(error)")
            
                self.remoteFound = false
        
                sem.signal()
    
                return
                
            } else {
                self.latitude = record?["latitude"] as? CLLocationDegrees
                self.longitude = record?["longitude"] as? CLLocationDegrees
                //print("-- Poll -- fetchRemote -- closure -- latitude:" +
                //    " \(String(describing: self.latitude))")
                //print("-- Poll -- fetchRemote -- closure -- longitude:" +
                //    " \(String(describing: self.longitude))")

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
    
    func pollRemote(packet: Location, mapView: MKMapView, mapUpdate: MapUpdate,
                    display: UILabel, pointer: UnsafeMutableRawPointer) {
        // fetchRemote() -> addPin() -> getEtaDistance()
        
        var rlat: CLLocationDegrees?
        var rlong: CLLocationDegrees?
        self.myPacket = packet
        
        // below code runs in a separate thread
        let queque = OperationQueue()
        queque.addOperation {
            print("\n===============================================================\n")
            print("-- Poll -- pollRemote -- in queque.addOperation()")
            print("\n===============================================================\n")
            
            print("-- Poll -- pollRemote -- into while{}")
            while true {
    
                // check pointer
                let x = pointer.load(as: TimeInterval.self)
                print("-- Poll -- pollRemote -- pointer: \(x)")
    
                // fetchRemote()
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
                
                    // do UI updates in the main thread
                    OperationQueue.main.addOperation() {
                    
                        let remove = false
                        _ = mapUpdate.addPin(packet: self.myPacket, mapView: mapView, remove)
                
                        (_, _) = mapUpdate.getEtaDistance(packet: self.myPacket, mapView: mapView, display: display, pointer: pointer)
    
                    }
                    
                    if packet.latitude != self.myPacket.latitude ||
                        packet.longitude != self.myPacket.longitude
                    {
                        self.myPacket.setLatitude(latitude: packet.latitude)
                        self.myPacket.setLongitude(longitude: packet.longitude)
                    }
                }
        
                print("-- Poll -- pollRemote -- sleep 2...")
                sleep(2)
                
                
            }
            print("\n===============================================================\n")
            print("-- Poll -- pollRemote -- Exit")
            print("\n===============================================================\n")
        }

    }

    
}


