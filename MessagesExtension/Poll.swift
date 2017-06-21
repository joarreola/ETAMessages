//
//  Poll.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit
import MapKit
import UIKit
import Messages

/// Poll iCloud for remote User's location record.
/// Request local notifications based on ETA data
///
/// fetchRemote(CLLocationDegrees?, CLLocationDegrees?)
/// pollRemote(Users, Location, MKMapView, EtaAdapter, UILabel)
/// etaNotification(UILabel)

class PollManager {
    private var latitude: CLLocationDegrees?
    private var longitude: CLLocationDegrees?
    private var remoteFound: Bool = false
    private let remoteUserName: String
    private var myLocalPacket: Location
    private var myRemotePacket: Location
    private var myEta: TimeInterval?
    private var myDistance: Double?
    private var etaOriginal: TimeInterval?
    private let cloudRemote: CloudAdapter
    static  var enabledPolling: Bool = false
    private let hasArrivedEta: Double = 35.0
    private let localNotification: ETANotifications
    var messagesVC: MSMessagesAppViewController?
    var timer: DispatchSourceTimer?
    
    init(remoteUserName: String) {
        print("-- PollManager -- init()")

        self.latitude = 0.0
        self.longitude = 0.0
        self.remoteUserName = remoteUserName
        self.myEta = 0.0
        self.etaOriginal = 0.0
        self.myDistance = 0.0
        
        self.cloudRemote  = CloudAdapter(userName: remoteUserName)
        self.myLocalPacket = Location()
        self.myRemotePacket = Location()
        self.localNotification = ETANotifications()
        self.messagesVC = nil
        
    }

    /// Fetch remoteUser's location record from iCloud
    /// - Parameters:
    ///     - whenDone: a closure that returns a Location parameter

// MARK: post comments

    func fetchRemote(whenDone: @escaping (Location) -> ()) -> () {
        print("-- PollManager -- fetchRemote(whenDone: @escaping (Location) -> ()) -> ()")
        
        cloudRemote.fetchRecord() {
            
            (packet: Location) in

            if packet.latitude == nil {
                print("-- PollManager -- fetchRemote(whenDone: @escaping (Location) -> ()) -> () -- cloudRemote.fetchRecord() -- closure -- failed")

                whenDone(packet)
                
            } else {
                print("-- PollManager -- fetchRemote(whenDone: @escaping (Location) -> ()) -> () -- cloudRemote.fetchRecord() -- closure -- latitude: \(String(describing: packet.latitude)) -- longitude: \(String(describing: packet.longitude))")
                
                print("-- PollManager -- fetchRemote(whenDone: @escaping (Location) -> ()) -> () -- cloudRemote.fetchRecord() -- closure -- call: whenDone(Location)")

                whenDone(packet)
            }
        }
    }

// MARK:-

    /// Poll iCloud for remote User's location record.
    /// while-loop runs in a background DispatchQueue.global thread.
    /// MapView updates are done in the DispatchQueue.main thread.
    /// Call etaNotification() to make local notifications posting
    ///     requests based on ETA data.
    /// - Parameters:
    ///     - localUser: local User instance
    ///     - remotePacket: remote location coordinates
    ///     - mapView: instance of MKMapView to re-center mapView
    ///     - eta: EtaAdapter instance with eta and distance properties
    ///     - display: UILabel instance display
    
    func pollRemote(localUser: Users, remotePacket: Location, mapView: MKMapView,
                    eta: EtaAdapter, display: UILabel) {
        print("-- PollManager -- pollRemote()")

        // request notification authorization
        //localNotification.requestAuthorization()

        // initialize to current local and remote postions
        self.myLocalPacket = Location(userName: localUser.name, location: localUser.location)

        self.myRemotePacket = Location(userName: remoteUserName, location: remotePacket)

        let mapUpdate = MapUpdate();
        
        // etaOriginal
        self.etaOriginal = eta.getEta()
        print("-- PollManager -- pollRemote() -- pre-DispatchSourceTimer -- self.etaOriginal: \(String(describing: self.etaOriginal))")

        // MARK: DispatchSourceTimer
    
        /**
         *
         * Below code runs in a separate thread
         *
         */
        print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- start configuration")
        
        let queue = DispatchQueue(label: "com.firm.app.timer", attributes: .concurrent)
        timer?.cancel()        // cancel previous timer if any
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleRepeating(deadline: .now(), interval: .seconds(2))
        print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- end configuration")
        
        timer?.setEventHandler(handler: {
            print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- in handler")

                // check pointer
                //self.myEta = eta.loadPointer()
                self.myEta = eta.getEta()
                self.myDistance = eta.getDistance()
                
                print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- self.myEta: \(String(describing: self.myEta)) self.myDistance: \(String(describing: self.myDistance))")
    
                // self.fetchRemote()
                print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- pre self.fetchRemote()")

                // MARK: start of post-comments

                print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- self.myEta: \(String(describing: self.myEta))")
                print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- etaOriginal: \(String(describing: self.etaOriginal))")

                if  self.myEta != nil && self.etaOriginal != nil &&
                    (self.myEta! != self.etaOriginal!)  || self.myEta! <= self.hasArrivedEta {
                    print("\n===============================================================")
                    print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- calling self.etaNotification(display: display)")
                    print("===============================================================\n")
                    
                    self.etaNotification(display: display)
                }

                self.fetchRemote() {
                    
                    (packet: Location) in
                    
                    if packet.latitude == nil {
                        print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- self.fetchRemote() -- closure -- returned nil")
                        
                        // UI updates on main thread
                        DispatchQueue.main.async { [weak self ] in
                            
                            if self != nil {
                                
                                // display localUserPacket
                                mapUpdate.displayUpdate(display: (display), packet: packet, string: "fetchRemote failed")
                                
                            }
                        }

                        return
                        
                    }
                    
                    if packet.latitude != self.myRemotePacket.latitude ||
                        packet.longitude != self.myRemotePacket.longitude ||
                        localUser.location.latitude != self.myLocalPacket.latitude ||
                        localUser.location.longitude != self.myLocalPacket.longitude
                    {
                        print("\n===============================================================")
                        print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- LOCATION CHANGED")
                        print("===============================================================\n")
            
                        print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- self.fetchRemote() -- closure -- remote latitude: \(String(describing: packet.latitude))")
                        print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- self.fetchRemote() -- closure -- remote longitude: \(String(describing: packet.longitude))")
                        
                        // update myRemotePacket and myLocalPacket
                        self.myRemotePacket.setLocation(latitude: packet.latitude, longitude: packet.longitude)
                        
                        self.myLocalPacket.setLocation(latitude: localUser.location.latitude, longitude: localUser.location.longitude)

                        // get eta and distance. Returns immediately, closure returns later
                        print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- self.fetchRemote() -- closure -- call: eta.getEtaDistance...")
                        
                        eta.getEtaDistance (localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, mapView: mapView, etaAdapter: eta, display: display)
                        
                        // UI updates on main thread
                        DispatchQueue.main.async { [weak self ] in
                            
                            if self != nil {
                               
                                // refreshMapView here vs. in eta.getEtaDistance()
                                print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- self.fetchRemote() -- call mapUpdate.refreshMapView()")
                                
                                mapUpdate.addPin(packet: (self?.myRemotePacket)!, mapView: mapView, remove: false)
                                
                                mapUpdate.refreshMapView(localPacket: (self?.myLocalPacket)!, remotePacket: (self?.myRemotePacket)!, mapView: mapView, eta: eta)
                                
                                mapUpdate.displayUpdate(display: display, localPacket: self!.myLocalPacket, remotePacket: self!.myRemotePacket, eta: eta)
                            }
                        }
                    } // end of location compare
                } // end of self.fetchRemote()
   
                // MARK:- end of post-comments

                // ETA == has-arrived, break out of while-loop
                if self.myEta != nil && (Double(self.myEta!) <= self.hasArrivedEta) {
                    print("\n===========================================================")
                    print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- STOPPING POLLREMOTE")
                    print("===============================================================\n")
                    
                    self.timer?.cancel()
                }
    
                // FIXME: switch to NSTime or iCloud notification
                print("\n===========================================================")
                print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- end of timer?.setEventHandler(handler")
                print("===============================================================\n")
    
        }) //  end of timer?.setEventHandler(handler)
        
        self.timer?.resume()

        // MARK:- end of DispatchQueue.global(qos: .background).async

    }

    /// Request local notifications based on ETA data
    /// - Parameters:
    ///     - display: UILabel instance display

    func etaNotification(display: UILabel) {
        print("-- PollManager -- etaNotification() -- etaOriginal: \(String(describing: self.etaOriginal)) myEta: \(self.myEta!)")
        
        let mapUpdate = MapUpdate()

        switch self.myEta! {
        case (self.etaOriginal! / 4) * 3:

            print("/n=====================================================================/n")
            print("-- PollManager -- etaNotification -- myEta == etaOriginal/4 * 3")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, string: "eta:\t\t\((self.myEta!)) sec", secondString: "3/4ths there")
            }
            setupLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            setupPseudoLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
    
        case (self.etaOriginal! / 4) * 2:
            
            print("/n=====================================================================/n")
            print("-- PollManager -- etaNotification() -- myEta == etaOriginal/4 * 2")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, string: "eta:\t\t\((self.myEta!)) sec", secondString: "Half-way there")
            }
            setupLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            setupPseudoLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            
        case (self.etaOriginal! / 4) * 1:
            
            print("/n=====================================================================/n")
            print("-- PollManager -- etaNotification() -- myEta == etaOriginal/4 * 1")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, string: "eta:\t\t\((self.myEta!)) sec", secondString: "1/4th there")
            }
            setupLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            setupPseudoLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            
        case 0.0...self.hasArrivedEta:

            print("/n=====================================================================/n")
            print("-- PollManager -- etaNotification() -- myEta == 0")
            print("/n=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, string: "eta:\t\t\((self.myEta!)) sec", secondString: "\(self.remoteUserName) Has arrived")
                
            }
            
            // MARK: local notification

            setupLocalNotification(message: (self.remoteUserName) + " Has arrived")
            
            // MARK:-
            
            // MARK: pseudo local notification
            
            setupPseudoLocalNotification(message: (self.remoteUserName) + " Has arrived")
            
            // MARK:-
            
            
        default:
            
            print("-- PollManager -- etaNotification -- default")
        }
        print("-- PollManager -- etaNotification -- exit")
    }
    
    /// localNotification()
    
    func setupLocalNotification(message: String) {
        
        print("-- PollManager -- etaNotification() -- setupLocalNotification()")

        self.localNotification.configureContent(milePost: message)
        
        self.localNotification.registerNotification()
        
        self.localNotification.scheduleNotification()
    }

    /// setupPseudoLocalNotification
    
    func setupPseudoLocalNotification(message: String) {
        
        if messagesVC != nil {
            
            print("-- PollManager -- etaNotification() -- setupPseudoLocalNotification() -- call: presentViewController()")
            
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    
                    self?.presentViewController(message: (self?.remoteUserName)! + " Has Arrived")
                }
            }
            
        } else {
            print("-- PollManager -- etaNotification() -- setupPseudoLocalNotification() -- messagesVC == nil")
        }
    }

    /// Note that polling has been enabled
    
    func enablePolling() {
        print("-- PollManager -- enablePolling")
        
        PollManager.enabledPolling = true
    }

    /// Note that polling has been disabled
    
    func disablePolling() {
        print("-- PollManager -- disablePolling")
        
        PollManager.enabledPolling = false
    }

    /// presentViewController()
    
    func presentViewController(message: String) {
        print("-- PollManager -- presentViewController() --------------------------")
        var controller: UIViewController!
        
            controller = instantiatePseudoNotificationsViewController(message: message)
        
            self.messagesVC?.addChildViewController(controller)
        
            controller.view.frame = (self.messagesVC?.view.bounds)!
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            self.messagesVC?.view.addSubview(controller.view)
            
            controller.view.leftAnchor.constraint(equalTo: (self.messagesVC?.view.leftAnchor)!).isActive = true
            controller.view.rightAnchor.constraint(equalTo: (self.messagesVC?.view.rightAnchor)!).isActive = true
            controller.view.topAnchor.constraint(equalTo: (self.messagesVC?.view.topAnchor)!).isActive = true
            controller.view.bottomAnchor.constraint(equalTo: (self.messagesVC?.view.bottomAnchor)!).isActive = true
        
            //self?.display.text = self?.message
            //controller.loadView()
            controller.didMove(toParentViewController: self.messagesVC)

    }
    
    /// instantiatePseudoNotificationsViewController()
    
    private func instantiatePseudoNotificationsViewController(message: String) -> UIViewController {
        print("-- PollManager -- instantiatePseudoNotificationsViewController()")

        guard let controller = self.messagesVC?.storyboard?.instantiateViewController(withIdentifier: "PseudoNotificationsViewController") as? PseudoNotificationsViewController else {
            fatalError("PseudoNotificationsViewController not found")
        }
        controller.message = message
        
        return controller
    }
    
}


