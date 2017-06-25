//
//  Cloud.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

/// Manage iCloud record accesses.
///
/// upload(Location)
/// fetchRecord(CLLocationDegrees?, CLLocationDegrees?)
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
        //print("-- CloudAdapter -- init -- locationRecordID: \(locationRecordID)")
    
        self.locationRecord = CKRecord(recordType: "Location",
                                       recordID: locationRecordID)
        //print("-- CloudAdapter -- init -- locationRecord: \(locationRecord)")
    
        self.myContainer = CKContainer.default()
        //print("-- CloudAdapter -- init -- myContainer.default()")
        publicDatabase = self.myContainer.publicCloudDatabase
        
    }
    
    /// Fetch a location record from iCloud. Delete if found, then save.
    /// - Parameters:
    ///     - whenDone: a closure that takes in a Location parameter

    // MARK: start post-comments

    func fetchRecord(whenDone: @escaping (Location) -> ()) -> () {
        
        //print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> ())")

        //fetchActivityIndicator.startAnimating()

        self.publicDatabase.fetch(withRecordID: self.locationRecordID) {

            (record, error) in
    
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    
                    //fetchActivityIndicator.stopAnimating()
                }
            }

            if let error = error {
                print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> ()  -- publicDatabase.fetch() -- closure -- Error: \(self.locationRecordID): \(error)")
    
                self.recordFound = false
    
                // callback to the passed closure
                //print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> () -- publicDatabase.fetch -- closure -- call: whenDone(self.recordFound): \(self.recordFound)")
    
                var packet: Location = Location()
                packet.setLocation(latitude: nil,longitude: nil)
                
                whenDone(packet)
    
                return
            }

            //print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> () -- publicDatabase.fetch -- closure -- Record found: \(self.locationRecordID)")
    
            self.latitude = record?["latitude"] as? CLLocationDegrees
            self.longitude = record?["longitude"] as? CLLocationDegrees
    
            //print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> () -- publicDatabase.fetch -- closure -- latitude: \(String(describing: self.latitude))")
            //print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> () -- publicDatabase.fetch -- closure --  longitude: \(String(describing: self.longitude))")

            self.recordFound = true
    
            // callback to the passed closure
            //print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> () -- closure -- call: whenDone(packet)")

            var packet: Location = Location()
            packet.setLocation(latitude: self.latitude, longitude: self.longitude)

            whenDone(packet)
        }
    }

    // MARK:- end post-comments

    /// Delete location record from iCloud

    func deleteRecord() {
        
        //print("-- CloudAdapter -- in deleteRecord()")
        
        self.publicDatabase.delete(withRecordID: self.locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- CloudAdapter -- deleteRecord() -- self.publicDatabase.delete() -- closure -- Error: \(self.locationRecordID): \(error)")
                
                return
            }
            //print("-- CloudAdapter -- deleteRecord() -- self.publicDatabase.delete() -- closure -- Record deleted: \(self.locationRecordID)")
            
        }
    }
    
    // MARK: start post-comment

    /// Upload a location record to iCloud. Delete then save.
    /// - Parameters:
    ///     - whenDone: a closure that takes in a Location parameter

    func upload(user: Users, uploadActivityIndicator: UIActivityIndicatorView, whenDone: @escaping (Bool) -> ()) -> () {
        // Called by enable() @IBAction function
        //print("-- CloudAdapter -- upload()")
        /*
        // Set the record’s fields.
        print("-- CloudAdapter -- upload() -- set coordinates")
        self.locationRecord["latitude"]  = user.location.latitude! as CKRecordValue
        self.locationRecord["longitude"] = user.location.longitude! as CKRecordValue
        */
        
        uploadActivityIndicator.startAnimating()

        self.publicDatabase.delete(withRecordID: self.locationRecordID) {
            (record, error) in

            if let error = error {
                print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- Error: \(self.locationRecordID): \(error)")

            } else {
            
                //print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- Record deleted: \(self.locationRecordID)")
            }
            
            self.locationRecordID = CKRecordID(recordName: self.user)
            self.locationRecord = CKRecord(recordType: "Location", recordID: self.locationRecordID)

            //print("-- CloudAdapter -- upload() -- set coordinates")
            self.locationRecord["latitude"]  = user.location.latitude! as CKRecordValue
            self.locationRecord["longitude"] = user.location.longitude! as CKRecordValue


            // call save() method while in the delete closure
            self.publicDatabase.save(self.locationRecord) {
                (record, error) in

                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        
                        uploadActivityIndicator.stopAnimating()
                    }
                }

                if error != nil {
                    // filter out "Server Record Changed" errors
                    //print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- self.publicDatabase.save -- closure -- Error: \(self.locationRecordID): \(error)")
                    
                    self.recordSaved = false
                    
                    // callback to the passed closure
                    //print("-- CloudAdapter -- upload() -- call: whenDone(self.recordSaved): \(self.recordSaved)")
                    
                    whenDone(self.recordSaved)

                    return
                }
                //print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- self.publicDatabase.save -- closure -- Record saved: \(self.locationRecordID)")
                
                self.recordSaved = true
                
                // callback to the passed closure
                //print("-- CloudAdapter -- upload() -- call: whenDone(self.recordSaved): \(self.recordSaved)")
                
                whenDone(self.recordSaved)
                
        // Mark: add a subscription to get a notification on a record change
        /*
                //print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- self.publicDatabase.save -- closure -- setup subscription -- RecordId: Oscar-iphone")
                
                let locationSubscription = CKQuerySubscription(recordType: "Location", predicate: NSPredicate(format: "TRUEPREDICATE"), options: CKQuerySubscriptionOptions.firesOnRecordCreation)
                
                let locationNotificationInfo = CKNotificationInfo()
                
                locationNotificationInfo.shouldSendContentAvailable = true
                
                locationNotificationInfo.shouldBadge = false
                
                locationNotificationInfo.alertBody = "Oscar-ipad updated"
                
                locationSubscription.notificationInfo = locationNotificationInfo

                let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [locationSubscription], subscriptionIDsToDelete: [])
        
                operation.modifySubscriptionsCompletionBlock = {
                    
                    savedSubscriptions, deletedSubscriptionIDs, operationError in
                    if operationError != nil {
    
                        print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- error: \(String(describing: operationError))")

                    } else {

                        //print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- Subscribed")
                    }
                }
                
                self.publicDatabase.add(operation)
        */
        // MARK:- end
                
            }
        }
    }

    // MARK:- end post-comments
    
}

