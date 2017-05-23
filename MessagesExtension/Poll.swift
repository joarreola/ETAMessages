//
//  Poll.swift
//  ETAMessages
//
//  Created by taiyo on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit

class Poll {
    private var latitude: CLLocationDegrees?
    private var longitude: CLLocationDegrees?
    private var remoteFound: Bool = false
    private let remoteUser: String
    private let locationRecordID: CKRecordID
    private let locationRecord: CKRecord
    private let myContainer: CKContainer
    
    init(remoteUser: String) {
        self.latitude = 0.0
        self.longitude = 0.0
        self.remoteUser = remoteUser
        
        self.locationRecordID = CKRecordID(recordName: remoteUser)
        print("-- Poll -- init -- set CKRecordID: \(locationRecordID)")
        
        // Create a record object.
        self.locationRecord = CKRecord(recordType: "Location",
                                       recordID: locationRecordID)
        print("-- Poll -- init -- locationRecord: \(locationRecord)")

        // private container
        self.myContainer = CKContainer(identifier: "iCloud.edu.ucsc.ETAMessages")
        print("-- Poll -- init -- set CKContainer: iCloud.edu.ucsc.ETAMessages")
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
                print("-- Poll -- fetchRemote -- closure -- latitude:" +
                    " \(String(describing: self.latitude))")
                print("-- Poll -- fetchRemote -- closure -- longitude:" +
                    " \(String(describing: self.longitude))")

                self.remoteFound = true
                
                sem.signal()

                return
            }
        }
        // got here after sem.signal()
        _ = sem.wait(timeout: DispatchTime.distantFuture)
        
        if(!self.remoteFound) {
            return (nil, nil)
        }
        
        return(self.latitude, self.longitude)
    }

}
