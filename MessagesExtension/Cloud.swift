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
    private let locationRecord: CKRecord
    private let myContainer: CKContainer
    private var recordSaved: Bool = false
    private var recordFound: Bool = false
    private let localUser: String
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?
    
    
    init(localUser: String) {
        self.localUser = localUser
        
        self.locationRecordID = CKRecordID(recordName: self.localUser)
        print("-- Cloud -- init -- locationRecordID: \(locationRecordID)")
    
        // Create a record object.
        self.locationRecord = CKRecord(recordType: "Location",
                                       recordID: locationRecordID)
        print("-- Cloud -- init -- locationRecord: \(locationRecord)")
    
        // private container
        self.myContainer = CKContainer(identifier: "iCloud.edu.ucsc.ETAMessages.MessagesExtention")
        print("-- Cloud -- init -- myContainer: iCloud.edu.ucsc.ETAMessages.MessagesExtention")

    }
    
    func upload(packet: Location) -> Bool? {
        // Called by the enabl() @IBAction function on a tap of the 'Enable' button

        var ret: Bool? = false
        
        // Set the record’s fields.
        locationRecord["latitude"]  = packet.latitude as CKRecordValue
        locationRecord["longitude"] = packet.longitude as CKRecordValue
        
        // start semaphore block to synchronize completion handles
        let sem = DispatchSemaphore(value: 0)

        myContainer.privateCloudDatabase.fetch(withRecordID: self.locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- Cloud -- upload - fetch: \(self.locationRecordID): \(error)")
                print("-- Cloud -- upload: Record doesn't exist, saving...\n")
        
                self.recordSaved = false
                
                self.saveRecord()
    
                sem.signal()

                return
    
            } else {
    
                print("-- Cloud -- upload: Record Exists, deleting...")
    
                self.deleteRecord()
    
                print("-- Cloud -- upload: Saving...")
                
                self.saveRecord()
                
                self.recordSaved = true
                
                sem.signal()

                return
            }
        }
        // got here after sem.signal()
        _ = sem.wait(timeout: DispatchTime.distantFuture)
    
        print("-- Cloud -- upload: end: self.recordSaved: \(self.recordSaved)\n")
    
        (self.recordSaved) ? (ret = true) : (ret = nil)
        
        return ret

    }
    
    func fetchRecord() -> (latitude: CLLocationDegrees?, longitude: CLLocationDegrees?) {
        // fetch a record
        
        print("-- Cloud -- fetchRecord -- CKContainer: iCloud.edu.ucsc.ETAMessages.MessagesExtention")
    
        // start semaphore block to synchronize completion handles
        let sem = DispatchSemaphore(value: 0)
        
        myContainer.privateCloudDatabase.fetch(withRecordID: locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- Cloud -- fetchRecord -- Error: \(self.locationRecordID): \(error)")
                
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
        // got here after sem.signal()
        _ = sem.wait(timeout: DispatchTime.distantFuture)
        
        if(!self.recordFound) {
            return (nil, nil)
        }

        return(self.latitude, self.longitude)
        
    }
    
    func saveRecord() {
        // save a record
        
        print("-- Cloud -- saveRecord -- CKContainer: iCloud.edu.ucsc.ETAMessages.MessagesExtention")
        
        // start semaphore block to synchronize completion handles
        let sem = DispatchSemaphore(value: 0)
        
        myContainer.privateCloudDatabase.save(locationRecord) {
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
            print(record as Any)
            
            self.recordSaved = true
            
            sem.signal()
        }
        // got here after sem.signal()
        _ = sem.wait(timeout: DispatchTime.distantFuture)
    }
    
    func deleteRecord() {
        // deletee a record
        
        print("-- Cloud -- deleteRecord -- CKContainer: iCloud.edu.ucsc.ETAMessages.MessagesExtention")
        
        // start semaphore block to synchronize completion handles
        let sem = DispatchSemaphore(value: 0)
        
        myContainer.privateCloudDatabase.delete(withRecordID: locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- upLoad -- deleteRecord -- Error: \(self.locationRecordID): \(error)")
                
                sem.signal()
                
                return
            }
            // Insert successfully delete record code
            print("-- Cloud -- deleteRecord -- Record deleted: \(self.locationRecordID)")
            
            sem.signal()
        }
        // got here after sem.signal()
        _ = sem.wait(timeout: DispatchTime.distantFuture)
    }
    
}
