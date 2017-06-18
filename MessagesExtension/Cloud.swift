//
//  Cloud.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit

/// Manage iCloud record accesses.
///
/// upload(Location)
/// fetchRecord(CLLocationDegrees?, CLLocationDegrees?)
/// saveRecord()
/// deleteRecord()

class CloudAdapter {
    private var locationRecordID: CKRecordID
    private var locationRecord: CKRecord
    private var myContainer: CKContainer
    private var recordSaved: Bool = false
    private var recordFound: Bool = false
    private let user: String
    private var latitude: CLLocationDegrees?
    private var longitude: CLLocationDegrees?
    private let publicDatabase: CKDatabase
    
    init(userName: String) {
        self.user = userName
        
        self.locationRecordID = CKRecordID(recordName: self.user)
        print("-- CloudAdapter -- init -- locationRecordID: \(locationRecordID)")
    
        self.locationRecord = CKRecord(recordType: "Location",
                                       recordID: locationRecordID)
        print("-- CloudAdapter -- init -- locationRecord: \(locationRecord)")
    
        self.myContainer = CKContainer.default()
        print("-- CloudAdapter -- init -- myContainer.default()")
        publicDatabase = self.myContainer.publicCloudDatabase
        
    }
    
    /// Upload location record to iCloud. Delete if found, then save.
    /// - Parameters:
    ///     - packet: location packet to upload
    /// - Returns: Upload success outcome: true or false
    
    // MARK: start pre-comments

    /*
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

        self.publicDatabase.fetch(withRecordID: self.locationRecordID) {
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
        _ = sem.wait(timeout: DispatchTime.now() + 5)
    
        print("-- Cloud -- upload: end: self.recordSaved: \(self.recordSaved)")
    
        (self.recordSaved) ? (ret = true) : (ret = false)
        
        return ret

    }
    */
    /// Fetach location record from iCloud
    /// - Parameters:
    ///     - latitude: record latitude field
    ///     - longitude: record longitude field

    /*
    func fetchRecord() -> (latitude: CLLocationDegrees?, longitude: CLLocationDegrees?) {
        // fetch a record
        
        print("-- Cloud -- in fetchRecord()")
    
        // start semaphore block to synchronize completion handler
        let sem = DispatchSemaphore(value: 0)
        //self.myContainer.privateCloudDatabase.fetch(withRecordID: self.locationRecordID) {
        //self.myContainer.publicCloudDatabase.fetch(withRecordID: self.locationRecordID) {
        self.publicDatabase.fetch(withRecordID: self.locationRecordID) {
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
        _ = sem.wait(timeout: DispatchTime.now() + 5)
        
        if(!self.recordFound) {
            return (nil, nil)
        }

        return(self.latitude, self.longitude)
        
    }
    */

    // MARK:- end pre-comments
    
    // MARK: start post-comments

    func fetchRecord(whenDone: @escaping (Location) -> ()) -> () {
        // fetch a record
        
        print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> ())")

        self.publicDatabase.fetch(withRecordID: self.locationRecordID) {

            (record, error) in
    
            if let error = error {
                print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> ()  -- publicDatabase.fetch() -- closure -- Error: \(self.locationRecordID): \(error)")
    
                self.recordFound = false
    
                // callback to the passed closure
                print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> () -- publicDatabase.fetch -- closure -- call: whenDone(self.recordFound): \(self.recordFound)")
    
                var packet: Location = Location()
                //packet.setLatitude(latitude: nil)
                //packet.setLongitude(longitude: nil)
                packet.setLocation(latitude: nil,longitude: nil)
                
                whenDone(packet)
    
                return
            }

            print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> () -- publicDatabase.fetch -- closure -- Record found: \(self.locationRecordID)")
    
            self.latitude = record?["latitude"] as? CLLocationDegrees
            self.longitude = record?["longitude"] as? CLLocationDegrees
    
            print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> () -- publicDatabase.fetch -- closure -- latitude: \(String(describing: self.latitude))")
            print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> () -- publicDatabase.fetch -- closure --  longitude: \(String(describing: self.longitude))")

            self.recordFound = true
    
            // callback to the passed closure
            print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> () -- closure -- call: whenDone(packet)")

            var packet: Location = Location()
            //packet.setLatitude(latitude: self.latitude)
            //packet.setLongitude(longitude: self.longitude)
            packet.setLocation(latitude: self.latitude, longitude: self.longitude)

            whenDone(packet)
        }
    }

    // MARK:- end post-comments

    // MARK: start pre-comments

    /// Save location record to iCloud
    /*
    func saveRecord() {
        // save a record
        
        print("-- CloudAdapter -- in saveRecord()")
        
        // start semaphore block to synchronize completion handler
        let sem = DispatchSemaphore(value: 0)
        
        self.publicDatabase.save(locationRecord) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- CloudAdapter -- saveRecord -- Error: \(self.locationRecordID): \(error)")
                
                self.recordSaved = false
                
                sem.signal()
                
                return
            }
            // Insert successfully saved record code
            print("-- CloudAdapter -- saveRecord -- Record saved: \(self.locationRecordID)")
            //print(record as Any)
            
            self.recordSaved = true
            
            sem.signal()
        }
        _ = sem.wait(timeout: DispatchTime.now() + 5)
    }
    */
    
    // MARK:- end of pre-comments

    /// Delete location record from iCloud
    func deleteRecord() {
        
        print("-- CloudAdapter -- in deleteRecord()")
        
        self.publicDatabase.delete(withRecordID: self.locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- CloudAdapter -- deleteRecord() -- self.publicDatabase.delete() -- closure -- Error: \(self.locationRecordID): \(error)")
                
                return
            }
            print("-- CloudAdapter -- deleteRecord() -- self.publicDatabase.delete() -- closure -- Record deleted: \(self.locationRecordID)")
            
        }
    }
    
    // MARK: start post-comment

    func upload(user: Users, whenDone: @escaping (Bool) -> ()) -> () {
        // Called by enable() @IBAction function
        print("-- CloudAdapter -- upload()")
        
        // Set the record’s fields.
        print("-- CloudAdapter -- upload() -- set coordinates")
        self.locationRecord["latitude"]  = user.location.latitude! as CKRecordValue
        self.locationRecord["longitude"] = user.location.longitude! as CKRecordValue
        
        self.publicDatabase.delete(withRecordID: self.locationRecordID) {
            (record, error) in

            if let error = error {
                print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- Error: \(self.locationRecordID): \(error)")

            } else {
            
                print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- Record deleted: \(self.locationRecordID)")
            }
            
            self.locationRecordID = CKRecordID(recordName: self.user)
            self.locationRecord = CKRecord(recordType: "Location", recordID: self.locationRecordID)

            // call save() method while in the delete closure
            self.publicDatabase.save(self.locationRecord) {
                (record, error) in

                if let error = error {
                    print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- self.publicDatabase.save -- closure -- Error: \(self.locationRecordID): \(error)")
                    
                    self.recordSaved = false
                    
                    // callback to the passed closure
                    print("-- CloudAdapter -- upload() -- call: whenDone(self.recordSaved): \(self.recordSaved)")
                    
                    whenDone(self.recordSaved)

                    return
                }
                print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- self.publicDatabase.save -- closure --Record saved: \(self.locationRecordID)")
                
                self.recordSaved = true
                
                // callback to the passed closure
                print("-- CloudAdapter -- upload() -- call: whenDone(self.recordSaved): \(self.recordSaved)")
                
                whenDone(self.recordSaved)
                
            }
        }
    }

    // MARK:- end post-comments
    
}
