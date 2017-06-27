//
//  Eta.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/31/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import MapKit

/// Adapter to ETA server for eta and distance data
///
/// eta { get set }
/// distance { get set }
/// getEtaDistance(Location, Location)

class EtaAdapter {
    //private var etaPointer: UnsafeMutableRawPointer
    static var eta: TimeInterval?
    static var distance: Double?
    private var mapUdate: MapUpdate
    private var previousDistance: TimeInterval? = nil
    
    init() {
        EtaAdapter.eta = nil
        EtaAdapter.distance = nil
        self.mapUdate = MapUpdate()

    }

    func setEta(eta: TimeInterval) {
        EtaAdapter.eta = eta
    }
    
    func getEta() -> TimeInterval? {
        return EtaAdapter.eta
    }
    
    func setDistance(distance: Double) {
        EtaAdapter.distance = distance
    }
    
    func getDistance() -> Double? {
        return EtaAdapter.distance
    }
    
    /// Makes mkDirections.calculate() call for eta and distance data
    /// - Parameters:
    ///     - localPacket: location coordinates for local user
    ///     - remotePacket: location coordintates for remote user
    ///     - mapView: refresh mapView
    ///     - etaAdapter: update eta and distance data
    ///     - display: update display content

    //func getEtaDistance (localPacket: Location, remotePacket: Location, mapView: MKMapView, etaAdapter: EtaAdapter, display: UILabel) {
    func getEtaDistance (localPacket: Location, remotePacket: Location, mapView: MKMapView, display: UILabel) {
        //print("-- EtaAdapter -- getEtaDistance(): get eta from local to remote device," + " and travel distance between devices")
    
        let mkDirReq: MKDirectionsRequest = MKDirectionsRequest()
        
        mkDirReq.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: localPacket.latitude!, longitude: localPacket.longitude!), addressDictionary: nil))

        mkDirReq.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: remotePacket.latitude!, longitude: remotePacket.longitude!), addressDictionary: nil))
        
        mkDirReq.requestsAlternateRoutes = false
        mkDirReq.transportType = .automobile
        //mkDirReq.transportType = .walking
        
        let mkDirections = MKDirections(request: mkDirReq)
        
        mkDirections.calculate { [ unowned self ] (response, error) in
            
            if error != nil {
                //print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- error -- Error: \(String(describing: error))")
                
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        // add pin and refresh mapView
                        //print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- error -- DispatchQueue.main.async -- closure")
                        /* will re-span map to a default value resulting in jumpy-map
                        etaAdapter.mapUdate.addPin(packet: remotePacket, mapView: mapView, remove: false)
                        
                        etaAdapter.mapUdate.refreshMapView(localPacket: localPacket, remotePacket: remotePacket, mapView: mapView, eta: etaAdapter)
                        */
                        self?.mapUdate.displayUpdate(display: display, localPacket: localPacket, remotePacket: remotePacket, string: "eta not available", secondString: "distance not available")
                    }
                }
                
                EtaAdapter.eta = nil
                EtaAdapter.distance = nil

                return
            }

            // can't get self.eta nor self.distance out of the closure on 1st poll
            guard let unwrappedResponse = response else {
                
                //print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closire -- unwrappedResponse -- Error: \(String(describing: error))")
                
                EtaAdapter.eta = nil
                EtaAdapter.distance = nil
                
                return
            }
            
            for route in unwrappedResponse.routes {
                //mapView.add(route.polyline)
                //mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                //print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- Distance: \(route.distance) meters")
                //print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- ETA: \(route.expectedTravelTime) sec")
                
                self.setEta(eta: route.expectedTravelTime)
                self.setDistance(distance: route.distance * 3.2808)

                //print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- self.distance: \(String(describing: self.distance!)) feet")
                //print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- self.eta: \(self.eta!)) sec")
                
                for step in route.steps {
                    print(step.instructions)
                }

                self.setEta(eta: route.expectedTravelTime)
                self.setDistance(distance: route.distance * 3.2808)
                
                if self.previousDistance == nil || Double(EtaAdapter.distance!) < Double(self.previousDistance!){
                    //print("--  EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- self.previousDistance = self.distance: \(String(describing: self.previousDistance))")

                    self.previousDistance = EtaAdapter.distance

                } else if Double(EtaAdapter.distance!) > Double(self.previousDistance!) {
                    // for simulation: don't update mapView if got a greater DISTANCE
                    //print("--  EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- eta > previousDistance: \(String(describing: self.distance)) , \(String(describing: self.previousDistance))")

                    return
                }
            }
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    // add pin and refresh mapView
                    //print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- DispatchQueue.main.async -- closure")
                    
                    self?.mapUdate.addPin(packet: remotePacket, mapView: mapView, remove: false)
                    
                    self?.mapUdate.refreshMapView(localPacket: localPacket, remotePacket: remotePacket, mapView: mapView, eta: self!)
                    
                    self?.mapUdate.displayUpdate(display: display, localPacket: localPacket, remotePacket: remotePacket, eta: self!)
                }
            }
        }
    }
}
