//
//  Eta.swift
//  ETAMessages
//
//  Created by taiyo on 5/31/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import MapKit

class EtaAdapter {
    var etaPointer: UnsafeMutableRawPointer
    var eta: TimeInterval?
    var distance: Double?
    
    init() {
        print("-- Eta -- init")
        self.eta = nil
        self.etaPointer = UnsafeMutableRawPointer.allocate(bytes: 64, alignedTo: 1)
        self.etaPointer.bindMemory(to: TimeInterval.self, capacity: 64)
        self.etaPointer.storeBytes(of: 0.0, as: TimeInterval.self)
        self.distance = nil

    }
    
    func storePointer(eta: TimeInterval) {
        self.etaPointer.storeBytes(of: eta, as: TimeInterval.self)
    }
    
    func deallocatePointer() {
        self.etaPointer.deallocate(bytes: 64, alignedTo: 8)
    }
    
    func loadPointer() -> TimeInterval {
        let x = self.etaPointer.load(as: TimeInterval.self)
        
        return x
    }
    
    func setEta(eta: TimeInterval) {
        self.eta = eta
    }
    
    func getEta() -> TimeInterval? {
        return self.eta
    }
    
    func setDistance(distance: Double) {
        self.distance = distance
    }
    
    func getDistance() -> Double? {
        return self.distance
    }
    
    func getEtaDistance (localPacket: Location, remotePacket: Location) {
        print("-- Eta -- getEtaDistance: get eta from local to remote device," +
            " and travel distance between devices")
        
        //let mapUpdate = MapUpdate()

        let mkDirReq: MKDirectionsRequest = MKDirectionsRequest()
        
        mkDirReq.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: localPacket.latitude, longitude: localPacket.longitude), addressDictionary: nil))
        
        mkDirReq.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: remotePacket.latitude, longitude: remotePacket.longitude), addressDictionary: nil))
        
        mkDirReq.requestsAlternateRoutes = false
        //mkDirReq.transportType = .automobile
        mkDirReq.transportType = .walking
        
        let mkDirections = MKDirections(request: mkDirReq)
        
        mkDirections.calculate { [ unowned self ] response, error in
            
            // can't get self.eta nor self.distance out of the closure on 1st poll
            guard let unwrappedResponse = response else {
                
                print("-- Eta -- mkDirections.calculate -- Error: \(String(describing: error))")
                
                self.eta = nil
                self.distance = nil
                
                return
            }
            
            for route in unwrappedResponse.routes {
                //mapView.add(route.polyline)
                //mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                print("-- Eta -- mkDirections.calculate -- closure -- Distance: \(route.distance) meters")
                print("-- Eta -- mkDirections.calculate -- closure -- ETA: \(route.expectedTravelTime) sec")
                
                self.setEta(eta: route.expectedTravelTime)
                self.setDistance(distance: route.distance * 3.2808)

                print("-- Eta -- mkDirections.calculate -- closure -- self.distance: \(String(describing: self.distance!)) feet")
                print("-- Eta -- mkDirections.calculate -- closure -- self.eta: \(self.eta!)) sec")
                
                for step in route.steps {
                    print(step.instructions)
                }

                // check etaPointer
                var x = self.loadPointer()
                print("-- Eta -- mkDirections.calculate -- closure -- etaPointer: \(x)")
                
                // set
                if self.eta != nil {
                    self.storePointer(eta: self.eta!)
                    print("-- Eta -- mkDirections.calculate -- closure -- updated etaPointer")
                }
                
                x = self.loadPointer()
                print("-- Eta -- mkDirections.calculate -- closure -- etaPointer: \(x)")
                
            }
            
            return
        }
        print("-- Eta -- mkDirections.calculate -- returning after closure")
        
        return
        
    }
}
