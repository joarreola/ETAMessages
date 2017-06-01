//
//  Cloud.swift
//  ETAMessages
//
//  Created by taiyo on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit

class Cloud {
    private var locationRecordID: CKRecordID
    private var locationRecord: CKRecord
    private var myContainer: CKContainer
    private var recordSaved: Bool = false
    private var recordFound: Bool = false
    private let localUser: String
    private var latitude: CLLocationDegrees?
    private var longitude: CLLocationDegrees?
    
    
    init(localUser: String) {
        self.localUser = localUser
        
        self.locationRecordID = CKRecordID(recordName: self.localUser)
        print("-- Cloud -- init -- locationRecordID: \(locationRecordID)")
    
        self.locationRecord = CKRecord(recordType: "Location",
                                       recordID: locationRecordID)
        print("-- Cloud -- init -- locationRecord: \(locationRecord)")
    
        self.myContainer = CKContainer(identifier: "iCloud.edu.ucsc.ETAMessages")
        print("-- Cloud -- init -- myContainer: iCloud.edu.ucsc.ETAMessages")

    }
    
    func upload(packet: Location) -> Bool {
        // Called by enable() and poll() @IBAction functions
        print("-- Cloud -- in upload()")

        var ret: Bool = false

        self.locationRecordID = CKRecordID(recordName: self.localUser)
        print("-- Cloud -- upload -- locationRecordID: \(locationRecordID)")
        self.locationRecord = CKRecord(recordType: "Location", recordID: locationRecordID)
        
        // Set the record’s fields.
        self.locationRecord["latitude"]  = packet.latitude as CKRecordValue
        self.locationRecord["longitude"] = packet.longitude as CKRecordValue
        
        // start semaphore block to synchronize completion handler
        let sem = DispatchSemaphore(value: 0)

        self.myContainer.privateCloudDatabase.fetch(withRecordID: self.locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- Cloud -- upload - fetch: \(self.locationRecordID): \(error)")
                print("-- Cloud -- upload: Record doesn't exist, saving...")
        
                self.recordSaved = false
                
                self.saveRecord()
    
                sem.signal()

                return
    
            } else {
    
                print("-- Cloud -- upload: Record Exists, deleting...")
    
                self.deleteRecord()

                print("-- Cloud -- upload: Saving...")
                
                self.locationRecordID = CKRecordID(recordName: self.localUser)
                self.locationRecord = CKRecord(recordType: "Location", recordID: self.locationRecordID)
                self.locationRecord["latitude"]  = packet.latitude as CKRecordValue
                self.locationRecord["longitude"] = packet.longitude as CKRecordValue
                
                self.saveRecord()
                
                self.recordSaved = true
                
                sem.signal()

                return
            }
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture)
    
        print("-- Cloud -- upload: end: self.recordSaved: \(self.recordSaved)")
    
        (self.recordSaved) ? (ret = true) : (ret = false)
        
        return ret

    }
    
    func fetchRecord() -> (latitude: CLLocationDegrees?, longitude: CLLocationDegrees?) {
        // fetch a record
        
        print("-- Cloud -- in fetchRecord()")
    
        // start semaphore block to synchronize completion handler
        let sem = DispatchSemaphore(value: 0)
        self.myContainer.privateCloudDatabase.fetch(withRecordID: self.locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- Cloud -- fetchRecord -- Error: \(self.locationRecordID): \(error)")
                
                self.recordFound = false

                sem.signal()
                
                return
    
            }
            self.latitude = record?["latitude"] as? CLLocationDegrees
            self.longitude = record?["longitude"] as? CLLocationDegrees
            print("-- Cloud -- fetchRecord -- closure -- latitude: \(String(describing: self.latitude))")
            print("-- Cloud -- fetchRecord -- closure --  longitude: \(String(describing: self.longitude))")
            
            self.recordFound = true
            
            sem.signal()
            
            return
    
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture)
        
        if(!self.recordFound) {
            return (nil, nil)
        }

        return(self.latitude, self.longitude)
        
    }
    
    func saveRecord() {
        // save a record
        
        print("-- Cloud -- in saveRecord()")
        
        // start semaphore block to synchronize completion handler
        let sem = DispatchSemaphore(value: 0)
        
        self.myContainer.privateCloudDatabase.save(locationRecord) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- Cloud -- saveRecord -- Error: \(self.locationRecordID): \(error)")
                
                self.recordSaved = false
                
                sem.signal()
                
                return
            }
            // Insert successfully saved record code
            print("-- Cloud -- saveRecord -- Record saved: \(self.locationRecordID)")
            //print(record as Any)
            
            self.recordSaved = true
            
            sem.signal()
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture)
    }
    
    func deleteRecord() {
        // delete a record
        
        print("-- Cloud -- in deleteRecord()")
        
        // start semaphore block to synchronize completion handler
        let sem = DispatchSemaphore(value: 0)
        
        self.myContainer.privateCloudDatabase.delete(withRecordID: self.locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- upLoad -- deleteRecord -- Error: \(self.locationRecordID): \(error)")
                
                sem.signal()
                
                return
            }
            print("-- Cloud -- deleteRecord -- Record deleted: \(self.locationRecordID)")
            
            sem.signal()
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture)
    }
    
}
