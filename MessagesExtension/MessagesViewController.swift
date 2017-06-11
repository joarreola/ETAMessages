//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import UIKit
import Messages
import MapKit
import CoreLocation
import UserNotifications

/// Messages Extension View Controller
///
/// locationManager(CLLocationManager, [CLLocation])
/// locationManager(CLLocationManager, NSError)
/// @IBAction func enable(UIBarButtonItem)
/// @IBAction func poll(UIBarButtonItem)
/// @IBAction func disable(UIBarButtonItem)

class MessagesViewController: MSMessagesAppViewController, MKMapViewDelegate,
                                                    CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    
    var eta = EtaAdapter()

    @IBOutlet weak var display: UILabel!

    // hardcoding for now
    let localUser  = Users(name: "Oscar-iphone")
    let remoteUser = Users(name: "Oscar-ipad")
    
    // can't pass above object to CloudAdapter(), PollManager(), or UploadingManager()
    // thus String literals
    var cloud = CloudAdapter(userName: "Oscar-iphone")
    var pollManager = PollManager(remoteUserName: "Oscar-ipad")
    var mapUpdate = MapUpdate()
    var uploading = UploadingManager(name: "Oscar-iphone")
    var gpsLocation = GPSLocation()
    
    // move these two to the respective class, Poll or GpsLocationAdapter
    var locPacket_updated: Bool = false
    var poll_entered: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("-- viewDidLoad -----------------------------------------------------")
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
        self.mapView.delegate = self

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
        print("-- willBecomeActive ------------------------------------------------")

    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
        print("-- didResignActive -------------------------------------------------")
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
        print("-- didReceive ------------------------------------------------------")
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
        print("-- didStartSending -------------------------------------------------")
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
        print("-- didCancelSending ------------------------------------------------")
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
        print("-- willTransition --------------------------------------------------")
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
        print("-- didTransition ---------------------------------------------------")
    }

    /**
     *
     * Called by the CLLocation Framework on GPS location changes
     *
     */
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        var lmPacket = Location()
        lmPacket.setLatitude(latitude: location!.coordinate.latitude)
        lmPacket.setLongitude(longitude: location!.coordinate.longitude)
        
        // refresh mapView from locationManager just once
        if !locPacket_updated
        {
            
            gpsLocation.updateUserCoordinates(localUser: localUser, lmPacket: lmPacket)
            
            self.mapUpdate.refreshMapView(packet: lmPacket, mapView: mapView)

            mapUpdate.displayUpdate(display: display, string: "locationManager...")
            
            locPacket_updated = true

        }
        
        // check if same location
        if lmPacket.latitude == localUser.location.latitude &&
            lmPacket.longitude == localUser.location.longitude
        {
            // nothing to update
            
            return
        }
        
        // A new location: update User's Location object
        print("-- locationManager -- location: '\(location!)'")
            
        gpsLocation.updateUserCoordinates(localUser: localUser, lmPacket: lmPacket)

        // refresh mapView
        print("-- locationManager -- refresh mapView")
            
        self.mapUpdate.refreshMapView(packet: localUser.location, mapView: mapView)


        //upload iCloud record
        if !gpsLocation.uploadToIcloud(localUser: localUser)
        {
            print("-- locationManager -- gpsLocation.uploadToIcloud() -- Failed")
            
            mapUpdate.displayUpdate(display: display, packet: localUser.location,
                                    string: "upload to iCloud failed")
            return

        }
            
        print("-- locationManager -- gpsLocation.uploadToIcloud() -- succeeded")

        // poll_entered is 0 if Poll button not yet tapped
        if poll_entered == 0
        {
            mapUpdate.displayUpdate(display: display, packet: localUser.location)
                
            return
                
        }

        // here because Poll button was tapped, need to check remote location

        print("-- locationManager -- call check_remote()")
                
        if !gpsLocation.checkRemote(pollRemoteUser: pollManager, localUser: localUser,
                                    remoteUser: remoteUser,
                                    mapView: mapView, eta: eta) {

            // failed to fetch RemoteUser's location.
            // Assumed due to Disabled by RemoteUser
            //  - reset poll_entered to 0
            //  - update display
            mapUpdate.displayUpdate(display: display, packet: localUser.location,
                                            string: "remote user location not found",
                                            secondString: "tap Poll to restart session")
                    
            self.poll_entered = 0
                    
        } else {
            // update display to include remotePacket and eta data
            mapUpdate.displayUpdate(display: display, localPacket: localUser.location,
                                            remotePacket: remoteUser.location,
                                            eta: self.eta)
        }
    }

    
    @nonobjc func locationManager(manager: CLLocationManager!,
                                  didFailWithError error: NSError!) {

        print("-- locationManager -- didFailWithError: \(error.description)")
        //let alert: UIAlertControllerStyle = UIAlertControllerStyle.alert
        //let errorAlert = UIAlertController(title: "Error",
        //                                   message: "Failed to Get Your Location",
        //                                   preferredStyle: alert)
        //errorAlert.show(UIViewController(), sender: manager)
        
    }

    /**
     *
     * Called on tap of Enable button
     *
     */
    @IBAction func enable(_ sender: UIBarButtonItem) {
        // Entry point to start uploading the current location to iCloud repository

        print("\n=================================================================")
        print("@IBAction func enable()")
        print("===================================================================")

        // display packet
        uploading.updateMap(display: display, packet: localUser.location)
        
        // Upload localUserPacket to Cloud repository
        if !uploading.uploadLocation(packet: localUser.location) {
            
            // display localUserPacket
            uploading.updateMap(display: display, packet: localUser.location,
                                string: "upload to cloud failed")

            return
        }
        
        // refresh mapView
        self.mapUpdate.refreshMapView(packet: localUser.location, mapView: mapView)
        
        // this allows for uploading of coordinates on LocalUser location changes
        // in locationManager()
        uploading.enableUploading()
        
        print("-- enable -- end\n")
    
    }

    /**
     *
     * Called on tap of Poll button
     *
     */
    @IBAction func poll(_ sender: UIBarButtonItem) {
        // check for remoteUser record

        print("\n==================================================================")
        print("@IBAction func poll()")
        print("====================================================================")

        // stop location updates as this path is for the stationary user
        //self.locationManager.stopUpdatingLocation()
        
        // vars
        var latitude: CLLocationDegrees
        var longitude: CLLocationDegrees
        poll_entered += 1
// MARK:
        // FIXME: temporary. will call pollManager.pollRemote() directly, removing all other code
        // start RemoteUser polling on 2nd tap... for now
        //  eta and distance checked at 1 sec interval
        if poll_entered > 1 {
/**
 * need local coordinates for test purposes via simulator location changes
 * - update README.md test instructions.
 *
            // moved to poll_entered = 2 => send tap of Poll button, to test
            //  locationmanager path
            self.locationManager.stopUpdatingLocation()
 *
 */

            print("-- Poll -- eta: \(String(describing: self.eta.getEta())) -- distance: \(String(describing: self.eta.getDistance()))")
    
            // add pin on mapView for remoteUser, re-center mapView, update span
            print("-- poll -- mapUpdate.addPin...")
            
            //self.mapUpdate.addPin(packet: localUserPacket, mapView: mapView, remove: false)
            self.mapUpdate.addPin(packet: remoteUser.location, mapView: mapView, remove: false)

            print("-- poll -- mapUpdate.refreshMapView...")
            
            self.mapUpdate.refreshMapView(localPacket: localUser.location,
                                          remotePacket: remoteUser.location,
                                          mapView: mapView, eta: eta)

            // note coordinates set, eta and distance on display
            mapUpdate.displayUpdate(display: display, localPacket: localUser.location,
                                    remotePacket: remoteUser.location, eta: eta)

            print("-- poll -- calling pollManager.pollRemote()")
    
            pollManager.pollRemote(localUser: localUser, remotePacket: remoteUser.location,
                            mapView: mapView, eta: eta, display: display)
            
            print("-- poll -- poll(): return\n")
            
            return
        }
// MARK:-

        // Upload localUserPacket to Cloud repository
        // Hardcode localuser for now
        print("-- poll --  upload local record once...")
        
        let cloudRet = cloud.upload(packet: localUser.location)

        if cloudRet == false {
            print("-- poll -- cloud.upload(localUserPacket) returned nil. Exiting poll()")
            
            // display localUserPacket
            mapUpdate.displayUpdate(display: display, packet: localUser.location,
                                    string: "upload to cloud failed")
            
            poll_entered = 0;

            print("-- poll -- poll(): return\n")

            return
    
        }
        
        // display localUserPacket
        mapUpdate.displayUpdate(display: display, packet: localUser.location)


        print("-- poll --  pollManager.fetchRemote for remote location record...")

        let fetchRet = pollManager.fetchRemote()
        
        if fetchRet.latitude == nil {
            print("-- poll -- pollManager.fetchRemote() returned nil. Exiting poll()")
            
            // display localUserPacket
            mapUpdate.displayUpdate(display: display, packet: localUser.location,
                                    string: "fetchRemote failed")
    
            poll_entered = 0;

            print("-- poll -- poll(): return\n")
    
            return
            
        }
        
        (latitude, longitude) = fetchRet as! (CLLocationDegrees, CLLocationDegrees)
        print("-- poll -- remote latitude: \(latitude)")
        print("-- poll -- remote longitude: \(longitude)")

        // update remoteUser Location
        remoteUser.location.setLatitude(latitude: latitude)
        remoteUser.location.setLongitude(longitude: longitude)
        
        // note coordinates set on display
        mapUpdate.displayUpdate(display: display, localPacket: localUser.location,
                                remotePacket: remoteUser.location)
        
        // get ETA and distance, [and refresh mapview from eta.getEtaDistance: FIX]
        print("-- poll -- eta.getEtaDistance...")
       
        eta.getEtaDistance (localPacket: localUser.location, remotePacket: remoteUser.location)

        // add pin and refresh mapView
        print("-- poll -- mapUpdate.addPin...")
        
        mapUpdate.addPin(packet: remoteUser.location, mapView: mapView, remove: false)

        print("-- poll -- mapUpdate.refreshMapView...")
        mapUpdate.refreshMapView(localPacket: localUser.location,
                                 remotePacket: remoteUser.location,
                                 mapView: mapView, eta: eta)

        print("-- poll -- return\n")

        return
    }
  
    /**
     *
     * Called on tap of Disable button
     *
     */
    @IBAction func disable(_ sender: UIBarButtonItem) {
        // Remove location record from iCloud repository.

        print("\n==================================================================")
        print("@IBAction func disable()")
        print("====================================================================")

        // clear display
        mapUpdate.displayUpdate(display: display)
        
        cloud.deleteRecord()

        mapUpdate.addPin(packet: localUser.location, mapView: mapView, remove: true)
        
        // refresh mapView for possible poll use
        self.mapUpdate.refreshMapView(packet: localUser.location, mapView: mapView)
        
        // stop location updates as this path is for the stationary user
        self.locationManager.stopUpdatingLocation()

        uploading.disableUploading()
        
    }

}
