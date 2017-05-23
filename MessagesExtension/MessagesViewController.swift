//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by taiyo on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import UIKit
import Messages
import MapKit
import CoreLocation

class MessagesViewController: MSMessagesAppViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    
    var locPacket = Location()

    @IBOutlet weak var display: UILabel!
    
    var cloud = Cloud(localUser: "Oscar-iphone")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("-- viewDidLoad ------------------------------------------------------")
        
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
        print("-- willBecomeActive -------------------------------------------------")
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
        print("-- didResignActive ---------------------------------------------------")
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
        print("-- didReceive -------------------------------------------------------")
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
        print("-- didStartSending --------------------------------------------------")
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
        print("-- didCancelSending -------------------------------------------------")
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
        print("-- willTransition ---------------------------------------------------")
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
        print("-- didTransition ----------------------------------------------------")
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        // Called by CLLocation framework on device location changes
        
        let location = locations.last
        
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude,
                                            longitude: location!.coordinate.longitude)
        
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.1,
                                                      longitudeDelta: 0.1)
        
        let region = MKCoordinateRegion(center: center, span: span)
        
        
        print("-- locationManager -- location: '\(location!)'")
        
        // refresh mapView
        self.mapView.setRegion(region, animated: true)
        
        // stop location updates
        self.locationManager.stopUpdatingLocation()
        
        // stuff Location structure
        locPacket.setLatitude(latitude: location!.coordinate.latitude)
        locPacket.setLongitude(longitude: location!.coordinate.longitude)
    }
    
    @nonobjc func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        print("didFailWithError: \(error.description)")
        let alert: UIAlertControllerStyle = UIAlertControllerStyle.alert
        let errorAlert = UIAlertController(title: "Error", message: "Failed to Get Your Location",
                                           preferredStyle: alert)
        errorAlert.show(UIViewController(), sender: manager)
        
    }
    
    @IBAction func enable(_ sender: UIBarButtonItem) {
        // Entry point to start uploading the current location to iCloud repository
        print("\n===============================================================\n")
        print("@IBAction func enable()\n")
        print("\n===============================================================\n")

        // vars
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees

        // display locPacket
        display.text = ""
        display.text =
        "local: (\(locPacket.latitude),\n         \(locPacket.longitude))"
        
        // Upload locPacket to Cloud repository
        // Hardcode localuser for now
        let cloudRet = cloud.upload(packet: locPacket)
        if (cloudRet == nil) {
            print("\n===============================================================\n")
            print("-- enable -- cloud.upload(locPacket) returned nil. Exiting enable\n")
            print("\n===============================================================\n")
            
            return
        }
        
        // recheck
        let fetchRet = cloud.fetchRecord()
        if (fetchRet.latitude == nil) {
            print("\n===============================================================\n")
            print("-- enable -- cloud.fetchRecord() returned nil: Exiting enable")
            print("\n===============================================================\n")
            
            return
        }
        
        (latitude, longitude) = fetchRet as! (CLLocationDegrees, CLLocationDegrees)
        print("-- enable -- latitude: \(latitude)")
        print("-- enable -- longitude: \(longitude)")

        print("-- enable -- Cloud(locPacket)\n")
    }
    
    @IBAction func disable(_ sender: UIBarButtonItem) {
        // Remove location record from iCloud repository.
        print("\n===============================================================\n")
        print("@IBAction func disable()\n")
        print("\n===============================================================\n")

        // clear display
        display.text = ""
        
        cloud.deleteRecord()
        
    }

}
