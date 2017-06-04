//
//  Eta.swift
//  ETAMessages
//
//  Created by taiyo on 5/31/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import MapKit

class Eta {
    var etaPointer: UnsafeMutableRawPointer
    var eta: TimeInterval?
    var distance: Double
    
    init() {
        print("-- Eta -- init")
        self.eta = 0.0
        self.etaPointer = UnsafeMutableRawPointer.allocate(bytes: 64, alignedTo: 1)
        self.etaPointer.bindMemory(to: TimeInterval.self, capacity: 64)
        self.etaPointer.storeBytes(of: 0.0, as: TimeInterval.self)
        self.distance = 0.0

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
    
    func getEta() -> TimeInterval {
        return self.eta!
    }
    
    func setDistance(distance: Double) {
        self.distance = distance
    }
    
    func getDistance() -> Double {
        return self.distance
    }
    
    func getEtaDistance (packet: Location, mapView: MKMapView, display: UILabel) {
        
        print("-- Eta -- getEtaDistance: get eta from local to remote device," +
            " and travel distance between devices")
        
        let mapUpdate = MapUpdate()

        let mkDirReq: MKDirectionsRequest = MKDirectionsRequest()
        
        mkDirReq.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: packet.latitude, longitude: packet.longitude), addressDictionary: nil))
        
        mkDirReq.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: packet.remoteLatitude, longitude: packet.remoteLongitude), addressDictionary: nil))
        
        mkDirReq.requestsAlternateRoutes = false
        //mkDirReq.transportType = .automobile
        mkDirReq.transportType = .walking
        
        let mkDirections = MKDirections(request: mkDirReq)
        
        mkDirections.calculate { [ unowned self ] response, error in
            
            // can't get self.eta nor self.distance out of the closure on 1st poll
            guard let unwrappedResponse = response else {
                
                print("-- Eta -- mkDirections.calculate -- Error: \(String(describing: error))")
                
                self.eta = nil
                
                return
            }
            
            for route in unwrappedResponse.routes {
                //mapView.add(route.polyline)
                //mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                print("-- Eta -- mkDirections.calculate -- closure -- Distance: \(route.distance) meters")
                print("-- Eta -- mkDirections.calculate -- closure -- ETA: \(route.expectedTravelTime) sec")
                
                self.setEta(eta: route.expectedTravelTime)
                self.setDistance(distance: route.distance * 3.2808)

                print("-- Eta -- mkDirections.calculate -- closure -- self.distance: \(self.distance) feet")
                print("-- Eta -- mkDirections.calculate -- closure -- self.eta: \(self.eta!)) sec")
                
                for step in route.steps {
                    print(step.instructions)
                }
                // MARK:
                    // FIXME: Do linear-regression
                    // FIXME: Move to mapUpdate
                // compute a delta to reset the span. Use switch for now
                let delta: Float
                switch self.distance {
                    
                case 0..<10:
                    
                    delta = 0.0001
                    
                case 10..<50:
                    
                    delta = 0.0001
                    
                case 50..<250:
                    
                    delta = 0.0001
                    
                case 250..<500:
                    
                    delta = 0.0005
                    
                case 500..<1000:
                    
                    delta = 0.005
                    
                case 1000..<2500:
                    
                    delta = 0.007
                    
                case 2500..<5000:
                    
                    delta = 0.01
                    
                case 5000..<10000:
                    
                    delta = 0.05
                    
                case 10000..<20000:
                    
                    delta = 0.1
                    
                case 20000..<40000:
                    
                    delta = 0.13
                    
                case 40000..<50000:
                    
                    delta = 0.2
                    
                case 50000..<100000:
                    
                    delta = 0.3
                    
                case 100000..<200000:
                    
                    delta = 0.4
                    
                default:
                    
                    delta = 0.1
                }
                print("-- Eta -- mkDirections.calculate -- closure -- delta: \(delta)")
                
                    // FIXME: move refreshMapView() and displayUpdate() out
                // for now continute to refresh mapView here
                print("-- Eta -- mkDirections.calculate -- closure -- call mapUpdate.refreshMapView...")
                
                mapUpdate.refreshMapView(packet: packet, mapView: mapView, delta: Double(delta))


                var string = [String]()
                string.append("local:\t\t( \(packet.latitude),\n\t\t\t\(packet.longitude) )\n")
                string.append("remote:\t( \(packet.remoteLatitude),\n\t\t\t\(packet.remoteLongitude) )\n")
                string.append("eta:\t\t\((self.eta!)) sec\n")
                string.append("distance:\t\((self.distance)) ft")
                
                print("-- Eta -- mkDirections.calculate -- closure -- call mapUpdate.displayUpdate...")
                
                mapUpdate.displayUpdate(display: display, stringArray: string)

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
                
                
                // MARK:-
            }
            
            return
        }
        print("-- Eta -- mkDirections.calculate -- returning after closure")
        
        return
        
    }
}
