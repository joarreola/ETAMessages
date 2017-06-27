//
//  MobilitySimulator.swift
//  ETAMessages
//
//  Created by taiyo on 6/21/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MobilitySimulator {
    static var mobilitySimulatorEnabled: Bool = false
    private let deltaLatitude = 0.09
    private let deltaLongitude = 0.20
    private var timer: DispatchSourceTimer?
    private var gpsLocation: GPSLocationAdapter
    private var mapUpdate: MapUpdate
    private var origLocation: Location
    private var tempUser: Users

    
    init(userName: String) {
        self.gpsLocation = GPSLocationAdapter()
        self.mapUpdate =  MapUpdate()
        self.origLocation = Location()
        self.tempUser = Users(name: userName)
    }
    
    func startMobilitySimulator(user: Users, display: UILabel, mapView: MKMapView, uploadActivityIndicator: UIActivityIndicatorView) {
        MobilitySimulator.mobilitySimulatorEnabled = true
        
        // move user away from (ex):
        //  37.340,128,049,289,19
        //-122.033,242,313,304,92
        
        // subtract 0.20 from longitude
        self.origLocation.latitude = user.location.latitude!
        self.origLocation.longitude = user.location.longitude!
        
        //print("-- MobilitySimulator -- start() -- DispatchSourceTimer -- self.origLocation.latitude: \(String(describing: self.origLocation.latitude))")
        //print("-- MobilitySimulator -- start() -- DispatchSourceTimer -- self.origLocation.longitude: \(String(describing: self.origLocation.longitude))")

        tempUser = Users(name: user.name)
        //tempUser.location.latitude = user.location.latitude! + deltaLatitude
        tempUser.location.latitude = user.location.latitude!
        tempUser.location.longitude = user.location.longitude! - deltaLongitude
        //tempUser.location.longitude = user.location.longitude!

        /**
         *
         * Below code runs in a separate thread
         *
         */
        //print("-- MobilitySimulator -- start() -- DispatchSourceTimer -- start configuration")
        
        let queue = DispatchQueue(label: "edu.ucsc.ETAMessages.timer", attributes: .concurrent)
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleRepeating(deadline: .now(), interval: .seconds(1))
        //print("-- MobilitySimulator -- start() -- DispatchSourceTimer -- end configuration")
        
        timer?.setEventHandler(handler: {
            //print("-- MobilitySimulator -- start() -- DispatchSourceTimer -- in handler")
            
            // upload new location
            //print("-- MobilitySimulator -- start() -- DispatchSourceTimer -- in handler -- tempUser.location.latitude: \(String(describing: self.tempUser.location.latitude))")
            //print("-- MobilitySimulator -- start() -- DispatchSourceTimer -- in handler -- tempUser.location.longitude: \(String(describing: self.tempUser.location.longitude))")
            
            self.gpsLocation.uploadToIcloud(user: self.tempUser, uploadActivityIndicator: uploadActivityIndicator) {
                
                (result: Bool) in

                if !result {
                    
                    //print("-- MobilitySimulator -- start() -- gpsLocation.uploadToIcloud() -- closure -- Failed")
                    
                    // UI updates on main thread
                    DispatchQueue.main.async { [weak self ] in
                        
                        if self != nil {
                            
                            self?.mapUpdate.displayUpdate(display: display, packet: (self?.tempUser.location)!, string: "upload to iCloud failed")
                            
                            //self?.mapUpdate.refreshMapView(packet: (self?.tempUser.location)!, mapView: mapView)
                        }
                    }
                    
                } else {
                    
                    //print("-- MobilitySimulator -- start() -- gpsLocation.uploadToIcloud() -- closure -- succeeded")
                    
                    //print("-- MobilitySimulator -- start() -- DispatchSourceTimer -- in handler -- tempUser.location.latitude: \(String(describing: self.tempUser.location.latitude))")
                    //print("-- MobilitySimulator -- start() -- DispatchSourceTimer -- in handler -- tempUser.location.longitude: \(String(describing: self.tempUser.location.longitude))")
                    
                    // UI updates on main thread
                    DispatchQueue.main.async { [weak self ] in
                        
                        if self != nil {
                            
                            self?.mapUpdate.displayUpdate(display: display, packet: (self?.tempUser.location)!, string: "uploaded to iCloud")
                            
                            self?.mapUpdate.refreshMapView(packet: (self?.tempUser.location)!, mapView: mapView)

                        }
                    }
                    
                    // get closer
                    if Double(self.tempUser.location.longitude!) + 0.005 > Double(self.origLocation.longitude!) {
                        
                        //self.tempUser.location.longitude = self.tempUser.location.longitude! + 0.0025
                        self.tempUser.location.longitude = self.tempUser.location.longitude! + 0.0005

                    } else {
                        
                        self.tempUser.location.longitude = self.tempUser.location.longitude! + 0.005
                    }
                    
                    // check if there
                    if Double(self.tempUser.location.longitude!) >= Double(self.origLocation.longitude!) || MobilitySimulator.mobilitySimulatorEnabled == false {
                        
                        //print("-- MobilitySimulator -- start() -- gpsLocation.uploadToIcloud() -- closure -- self.timer?.cancel()")
                        
                        self.timer?.cancel()
                        
                        DispatchQueue.main.async { [weak self ] in
                            
                            if self != nil {
                                
                                self?.mapUpdate.displayUpdate(display: display, packet: (self?.tempUser.location)!, string: "Simulation Completed")
                            }
                        }
                    }
                }
            }

        }) //  end of timer?.setEventHandler(handler)
        
        self.timer?.resume()
        

    }
    
    func stopMobilitySimulator() {
        
        MobilitySimulator.mobilitySimulatorEnabled = false
    }
    
}
