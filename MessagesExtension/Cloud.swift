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
        self.locationRecord = CKRecord(recordType: "Location",
                                       recordID: locationRecordID)
        self.myContainer = CKContainer.default()
        publicDatabase = self.myContainer.publicCloudDatabase
        
    }
    
    /// Fetch a location record from iCloud. Delete if found, then save.
    /// - Parameters:
    ///     - whenDone: a closure that takes in a Location parameter

    func fetchRecord(fetchActivity: UIActivityIndicatorView, whenDone: @escaping (Location) -> ()) -> () {

        // UI updates on main thread
        DispatchQueue.main.async { [weak self ] in
            
            if self != nil {
                
                fetchActivity.startAnimating()
            }
        }

        self.publicDatabase.fetch(withRecordID: self.locationRecordID) {

            (record, error) in
    
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    
                    fetchActivity.stopAnimating()
                }
            }

            if let error = error {
                print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> ()  -- publicDatabase.fetch() -- closure -- Error: \(self.locationRecordID): \(error)")
    
                self.recordFound = false
    
                // callback to the passed closure

                var packet: Location = Location()
                packet.setLocation(latitude: nil,longitude: nil)
                
                whenDone(packet)
    
                return
            }

            self.latitude = record?["latitude"] as? CLLocationDegrees
            self.longitude = record?["longitude"] as? CLLocationDegrees
            self.recordFound = true
    
            // callback to the passed closure

            var packet: Location = Location()
            packet.setLocation(latitude: self.latitude, longitude: self.longitude)

            whenDone(packet)
        }
    }

    // MARK:- end post-comments

    /// Delete location record from iCloud

    func deleteRecord() {

        self.publicDatabase.delete(withRecordID: self.locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- CloudAdapter -- deleteRecord() -- self.publicDatabase.delete() -- closure -- Error: \(self.locationRecordID): \(error)")
                
                return
            }
        }
    }
    
    // MARK: start post-comment

    /// Upload a location record to iCloud. Delete then save.
    /// - Parameters:
    ///     - whenDone: a closure that takes in a Location parameter

    func upload(user: Users, uploadActivityIndicator: UIActivityIndicatorView, whenDone: @escaping (Bool) -> ()) -> () {
        // Called by enable() @IBAction function
        
        // UI updates on main thread
        DispatchQueue.main.async { [weak self ] in
            
            if self != nil {
                
                uploadActivityIndicator.startAnimating()
            }
        }

        self.publicDatabase.delete(withRecordID: self.locationRecordID) {
            (record, error) in

            if let error = error {
                print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- Error: \(self.locationRecordID): \(error)")

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

                    self.recordSaved = false
                    
                    // callback to the passed closure

                    whenDone(self.recordSaved)

                    return
                }

                self.recordSaved = true
                
                // callback to the passed closure
                
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
    
}

