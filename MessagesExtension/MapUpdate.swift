//
//  MapUpdate.swift
//  ETAMessages
//
//  Created by taiyo on 5/23/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import Messages
import MapKit
import CoreLocation
import CloudKit

//class MapUpdate: MessagesViewController {
class MapUpdate {
    private var locLatitude: CLLocationDegrees = 0.0
    private var locLongitude: CLLocationDegrees = 0.0
    private var remLatitude: CLLocationDegrees = 0.0
    private var remLongitude: CLLocationDegrees = 0.0
    private var latDistTo: Double = 0.0
    private var lngDistTo: Double = 0.0
    private var centerLatitude: CLLocationDegrees = 0.0
    private var centerLongitude: CLLocationDegrees = 0.0
    public var eta: TimeInterval? = nil
    public var distance: Double = 0.0
    
    func showRemote (packet: Location, mapView: MKMapView) {
        
    }

    func addPin (packet: Location, mapView: MKMapView) -> MKPointAnnotation {
        print("-- MapUpdate -- addPin: add pin for remoteUser")
    
        self.locLatitude  = packet.latitude
        self.locLongitude = packet.longitude
        self.remLatitude  = packet.remoteLatitude
        self.remLongitude = packet.remoteLongitude
        
        // Define an appropriate annotation object
        let pointAnnotation: MKPointAnnotation = MKPointAnnotation()
        mapView.removeAnnotation(pointAnnotation)
    
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: remLatitude,
                                                            longitude: remLongitude)
        mapView.addAnnotation(pointAnnotation)
        
        return pointAnnotation
    }

    func centerView (packet: Location, mapView: MKMapView) -> CLLocationCoordinate2D {
        print("-- MapUpdate -- centerView: center mapView between local and remote users")
    
        let lLat  = packet.latitude
        let lLong = packet.longitude
        let rLat  = packet.remoteLatitude
        let rLong = packet.remoteLongitude
        var centerLatitude: CLLocationDegrees
        var centerLongitude: CLLocationDegrees

        latDistTo = lLat.distance(to: rLat) / 2
        lngDistTo = lLong.distance(to: rLong) / 2
        
        (lLat > rLat) ? (centerLatitude = rLat + latDistTo) :
            (centerLatitude = lLat + latDistTo)
        (lLong > rLong) ? (centerLongitude = rLong + lngDistTo) :
            (centerLongitude = lLong + lngDistTo)
        
        // re-center
        let center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: centerLatitude,
                                            longitude: centerLongitude)
        
        mapView.setCenter(center, animated: true)
    
        return center
        
    }

    func getEtaDistance (packet: Location, mapView: MKMapView, pointAnnotation: MKPointAnnotation,
                         center: CLLocationCoordinate2D) ->
            (eta: TimeInterval?, distance: Double) {

        print("-- MapUpdate -- getEtaDistance: get eta from local to remote device," +
                    " and travel distance between devices")
    
        // compose a request
        let mkDirReq: MKDirectionsRequest = MKDirectionsRequest()
        
        // source
        mkDirReq.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: packet.latitude, longitude: packet.longitude), addressDictionary: nil))
        
        // destination
        mkDirReq.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: packet.remoteLatitude, longitude: packet.remoteLongitude), addressDictionary: nil))
        
        mkDirReq.requestsAlternateRoutes = false
        //request.transportType = .car
        mkDirReq.transportType = .walking
        
        let mkDirections = MKDirections(request: mkDirReq)

        // start semaphore block to synchronize completion handler
        //let sem = DispatchSemaphore(value: 0)
        
        print("-- MapUpdate -- pre --- mkDirections.calculate()")
        mkDirections.calculate { [unowned self] response, error in
            // can't get self.eta nor self.distance out of the closure
            guard let unwrappedResponse = response else {
                
                print("-- MapUpdate -- mkDirections.calculate -- Error: \(String(describing: error))")
                //sem.signal()
                
                self.eta = nil

                return
            }
            
            for route in unwrappedResponse.routes {
                mapView.add(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                print("-- MapUpdate -- mkDirections.calculate -- closure -- Distance: \(route.distance/1000) meters")
                print("-- MapUpdate -- mkDirections.calculate -- closure -- ETA: \(route.expectedTravelTime/60) min")
                self.eta = route.distance * 3.2808
                self.distance = route.expectedTravelTime
                print("-- MapUpdate -- mkDirections.calculate -- closure -- Distance: \(self.distance) feet")
                print("-- MapUpdate -- mkDirections.calculate -- closure -- ETA: \(String(describing: self.eta)) sec")
                
                for step in route.steps {
                    print(step.instructions)
                }
                
                // compute a delta to reset the span
                let delta: Float
                switch self.distance {
                    
                case 0..<100:
                    
                    delta = 0.0001
                    
                case 100..<500:
                    
                    delta = 0.005
                
                case 500..<1000:
                    
                    delta = 0.001
                    
                case 1000..<1500:
                    
                    delta = 0.05
    
                case 1500..<2000:
                    
                    delta = 0.01
                    
                case 2000..<5000:
                    
                    delta = 0.5
        
                case 5000..<100000:
                    
                    delta = 0.1
                    
                default:
                    
                    delta = 0.1
                }
                print("delta: \(delta)")
                
                let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(delta),
                                                              longitudeDelta: CLLocationDegrees(delta))
                let region = MKCoordinateRegion(center: center, span: span)
                mapView.setRegion(region, animated: true)

            }
        
        }
        print("-- MapUpdate mkDirections.calculate -- Post closure")
        print("self.eta: \(String(describing: self.eta))")
        print("self.distance: \(self.distance)")

        return (self.eta, self.distance)

    }

    func snapView (packet: Location, mapView: MKMapView) {
        
    }
}
