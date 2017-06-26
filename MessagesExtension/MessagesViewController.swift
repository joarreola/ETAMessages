//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import UIKit
//import AppKit
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

class MessagesViewController: MSMessagesAppViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    // notifications delegate
    weak var delegate: UNUserNotificationCenterDelegate?

    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    
    var eta = EtaAdapter()

    @IBOutlet weak var display: UILabel!

    @IBOutlet weak var fetchActivity: UIActivityIndicatorView!
    @IBOutlet weak var uploadActivity: UIActivityIndicatorView!
    @IBOutlet weak var uploadLabel: UILabel!
    @IBOutlet weak var fetchLabel: UILabel!
    
    @IBOutlet weak var etaProgress: UIProgressView!
    
    @IBOutlet weak var progressDisplay: UILabel!
    
    
    // hardcoding for now
    let localUser  = Users(name: "Oscar-iphone")
    let remoteUser = Users(name: "Oscar-ipad")
    
    // can't pass above object to CloudAdapter(), PollManager(), or UploadingManager()
    // thus String literals
    //var cloud = CloudAdapter(userName: "Oscar-iphone") // done in UploadingManager()
    var pollManager = PollManager(remoteUserName: "Oscar-ipad")
    var mapUpdate = MapUpdate()
    var uploading = UploadingManager(name: "Oscar-iphone")
    var gpsLocation = GPSLocationAdapter()
    var mobilitySimulator = MobilitySimulator(userName: "Oscar-iphone")
    
    // move these two to the respective class, Poll or GpsLocationAdapter
    var locPacket_updated: Bool = false
    var poll_entered: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //print("-- viewDidLoad -----------------------------------------------------")
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true

        self.mapView.delegate = self
        
        self.pollManager.messagesVC = self
        
        self.etaProgress.transform = self.etaProgress.transform.scaledBy(x: 1, y: 10)
        let progress = (eta.eta == nil) ? 0.0 : Float(eta.eta!)
        self.etaProgress.setProgress(progress, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //print("-- viewWillAppear ------------------------------------------------")

    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        //print("-- didReceiveMemoryWarning ------------------------------------------------")
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
        //print("-- willBecomeActive ------------------------------------------------")

    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
        //print("-- didResignActive -------------------------------------------------")
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
        //print("-- didReceive ------------------------------------------------------")
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
        //print("-- didStartSending -------------------------------------------------")
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
        //print("-- didCancelSending ------------------------------------------------")
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
        //print("-- willTransition --------------------------------------------------")
        
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
        //print("-- didTransition ---------------------------------------------------")
    }
    


    /**
     *
     * Called by the CLLocation Framework on GPS location changes
     *
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // locationManager(:didUpdateLocations) guarantees that locations will not
        // be empty
        let location = locations.last!
        let lmPacket = Location(userName: "", location: location)
        
        // refresh mapView from locationManager just once
        if !locPacket_updated
        {
            
            self.localUser.location = lmPacket
            
            self.mapUpdate.refreshMapView(packet: lmPacket, mapView: mapView)

            mapUpdate.displayUpdate(display: display, string: "locationManager...")
            
            locPacket_updated = true

        }
        
        // nothing to update if same location
        if lmPacket.latitude == localUser.location.latitude &&
            lmPacket.longitude == localUser.location.longitude
        {
            
            return
        }
        
        // A new location: update User's Location object
        //print("-- locationManager -- location: '\(location)'")
            
        //gpsLocation.updateUserCoordinates(localUser: localUser, packet: lmPacket)
        self.localUser.location = lmPacket

        if (UploadingManager.enabledUploading) {
            // refresh mapView if enabledUploading
            
            // don't refresh MapView centered on localUser if polling enabled
            if !PollManager.enabledPolling {
                //print("-- locationManager -- refresh mapView for localUser")

                self.mapUpdate.refreshMapView(packet: localUser.location, mapView: mapView)
            }

// MARK: post-comments
            //print("-- locationManager -- call: self.gpsLocation.uploadToIcloud(user: localUser)")

            //uploadActivity.startAnimating()

            self.gpsLocation.uploadToIcloud(user: localUser, uploadActivityIndicator: uploadActivity) {
                
                (result: Bool) in
                
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        
                        //self?.uploadActivity.stopAnimating()
                    }
                }

                // MARK: start post-comments
                
                //print("-- locationManager -- gpsLocation.uploadToIcloud(localUser: localUser) -- closure -- call self.gpsLocation.handleUploadResult(result)")

                self.gpsLocation.handleUploadResult(result, display: self.display, localUser: self.localUser, remoteUser: self.remoteUser, mapView: self.mapView, eta: self.eta, pollManager: self.pollManager)
                
                // MARK:- end post-comments
                
            }

// MARK:-

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
        
        // reenable in case disabled
        self.locationManager.startUpdatingLocation()

        //print("\n=================================================================")
        //print("@IBAction func enable()")
        //print("===================================================================")

// MARK: post-comments

        // Upload localUserPacket to Cloud repository
        
        //self.uploadActivity.startAnimating()
        
        self.uploading.uploadLocation(user: localUser, uploadActivityIndicator: uploadActivity) {
            
            (result) in

            if !result {
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {

                        // display localUserPacket and error message
                        self?.uploading.updateMap(display: (self?.display)!, packet: (self?.localUser.location)!, string: "upload to iCloud failed")
                        
                        //self?.uploadActivity.stopAnimating()
                    }
                }

                return
            }
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    // display localUserPacket and error message
                    self?.uploading.updateMap(display: (self?.display)!, packet: (self?.localUser.location)!, string: "uploaded to iCloud")
                    
                    //self?.uploadActivity.stopAnimating()
                }
            }

            // this allows for uploading of coordinates on LocalUser location changes
            // in locationManager()
            self.uploading.enableUploading()
        }
        
        // refresh mapView
        self.mapUpdate.refreshMapView(packet: self.localUser.location, mapView: self.mapView)

// MARK: -

    }

    @IBAction func mobilitySumulation(_ sender: UIBarButtonItem) {
        
        //print("\n==================================================================")
        //print("@IBAction func mobilitySumulation()")
        //print("====================================================================")
        
        self.locationManager.stopUpdatingLocation()
         
        //print("-- mobilitySumulation -- starting mobility simulation")
         
        mobilitySimulator.startMobilitySimulator(user: localUser, display: display, mapView: mapView, uploadActivityIndicator: uploadActivity)

    }

    /**
     *
     * Called on tap of Poll button
     *
     */
    @IBAction func poll(_ sender: UIBarButtonItem) {
        // check for remoteUser record

        //print("\n==================================================================")
        //print("@IBAction func poll()")
        //print("====================================================================")
/*
        // vars
        poll_entered += 1
    
// MARK:
        // FIXME: temporary. will call pollManager.pollRemote() directly, removing all other code
    
        // start RemoteUser polling on 2nd tap... for now
        //  eta and distance checked at 2 sec interval
        if poll_entered > 1 {

            print("-- Poll -- eta: \(String(describing: self.eta.getEta())) -- distance: \(String(describing: self.eta.getDistance()))")
    
            // add pin on mapView for remoteUser, re-center mapView, update span
            print("-- poll -- mapUpdate.addPin...")
            
            self.mapUpdate.addPin(packet: remoteUser.location, mapView: mapView, remove: false)

            print("-- poll -- mapUpdate.refreshMapView...")
            
            self.mapUpdate.refreshMapView(localPacket: localUser.location, remotePacket: remoteUser.location, mapView: mapView, eta: eta)

            // note coordinates set, eta and distance on display
            mapUpdate.displayUpdate(display: display, localPacket: localUser.location, remotePacket: remoteUser.location, eta: eta)

            print("-- poll -- calling pollManager.pollRemote()")
    
            pollManager.pollRemote(localUser: localUser, remotePacket: remoteUser.location, mapView: mapView, eta: eta, display: display)

            // enable in case stationary user moves during or after polling
            self.locationManager.startUpdatingLocation()
            self.uploading.enableUploading()
            
            return
        }
 */
// MARK:-

// MARK: Does stationary user have a need to upload location to iCloud?
        /*
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
        */
// MARK:-
        
        // display localUserPacket
        self.mapUpdate.displayUpdate(display: self.display, packet: self.localUser.location)
        
        //print("-- poll --  pollManager.fetchRemote for 1st remote location record...")

// MARK: start of post-comments

        self.fetchActivity.startAnimating()

        self.pollManager.fetchRemote() {
            
            (packet: Location) in
            
            if packet.latitude == nil {
                //print("-- poll -- self.pollManager.fetchRemote() - closure -- failed")
                
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        
                        // display localUserPacket
                        self?.mapUpdate.displayUpdate(display: (self?.display)!, packet: (self?.localUser.location)!, string: "fetchRemote failed")
                        
                        self?.fetchActivity.stopAnimating()

                    }
                }
                
                // reset poll_entered to get a chance to recheck for remoteRecord before
                // calling pollManager.pollRemote(), which polls for the record
                // But, could instead let pollManager.pollRemote() to exit after N (10?)
                // retries?
                //self.poll_entered = 0;

                return

            } else {

                //print("-- poll -- self.pollManager.fetchRemote() - closure -- remote latitude: \(String(describing: packet.latitude))")
                //print("-- poll -- self.pollManager.fetchRemote() - closure -- remote longitude: \(String(describing: packet.longitude))")
                
                // update remoteUser Location
                self.remoteUser.location.setLocation(latitude: packet.latitude!, longitude: packet.longitude!)
                
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        // note coordinates set on display
                        self?.mapUpdate.displayUpdate(display: (self?.display)!, localPacket: (self?.localUser.location)!, remotePacket: packet)
                        
                        self?.fetchActivity.stopAnimating()
                    }
                }
                
                // get eta and distance. Returns immediately, closure returns later
                //print("-- poll -- self.pollManager.fetchRemote() -- closure -- call: eta.getEtaDistance")
                
                self.eta.getEtaDistance (localPacket: self.localUser.location, remotePacket: self.remoteUser.location, mapView: self.mapView, etaAdapter: self.eta, display: self.display)
                
                //print("-- poll -- self.pollManager.fetchRemote() -- closure -- call: pollManager.pollRemote")
// should not call pollRemote() after calling getEtaDistance, as they will trip over
// each other!
                // addpin() display() and refreshMapView() are called in pollRemote()
                self.pollManager.pollRemote(localUser: self.localUser, remotePacket: self.remoteUser.location, mapView: self.mapView, eta: self.eta, display: self.display, etaProgressView: self.etaProgress, progressDisplay: self.progressDisplay)
                
                // enable in case stationary user moves during or after polling
                self.locationManager.startUpdatingLocation()
                self.uploading.enableUploading()
                
                //print("-- poll -- self.pollManager.fetchRemote() -- exit closure")
            }
            
            // should polling be enabled here or outside self.pollManager.fetchRemote()?
            self.pollManager.enablePolling()
        }

// MARK:- end of post-comments

    }
  
    /**
     *
     * Called on tap of Disable button
     *
     */
    @IBAction func disable(_ sender: UIBarButtonItem) {
        // Remove location record from iCloud repository.

        //print("\n==================================================================")
        //print("@IBAction func disable()")
        //print("====================================================================")

        // clear display
        mapUpdate.displayUpdate(display: display)
        
        mapUpdate.addPin(packet: localUser.location, mapView: mapView, remove: true)
        
        // refresh mapView for possible poll use
        self.mapUpdate.refreshMapView(packet: localUser.location, mapView: mapView)
        
        // stop location updates as this path is for the stationary user
        self.locationManager.stopUpdatingLocation()

        uploading.disableUploading()
        pollManager.disablePolling()
        poll_entered = 0;
        mobilitySimulator.stopMobilitySimulator()
        
    }

}

