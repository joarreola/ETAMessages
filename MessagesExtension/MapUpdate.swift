//
//  MapUpdate.swift
//  ETAMessages
//
//  Created by taiyo on 5/23/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation
import CloudKit

class MapUpdate {
    private var locLatitude: CLLocationDegrees = 0.0
    private var locLongitude: CLLocationDegrees = 0.0
    private var remLatitude: CLLocationDegrees = 0.0
    private var remLongitude: CLLocationDegrees = 0.0
    private var latDistTo: Double = 0.0
    private var lngDistTo: Double = 0.0
    private var centerLatitude: CLLocationDegrees = 0.0
    private var centerLongitude: CLLocationDegrees = 0.0
    private var eta: Int? = 0
    private var distance: Double = 0.0

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

    func centerView (packet: Location, mapView: MKMapView) {
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
        let center = CLLocationCoordinate2D(latitude: centerLatitude,
                                            longitude: centerLongitude)
        
        mapView.setCenter(center, animated: true)
        
    }
    
    func getEtaDistance (packet: Location, mapView: MKMapView, pointAnnotation: MKPointAnnotation) ->
        (eta: Int?, distance: Double) {
        print("-- MapUpdate -- getEtaDistance: get eta from local to remote device," +
            " and travel distance between devices")
        
        // compose source MKMapItem
        var source: MKMapItem = MKMapItem()
        source = MKMapItem.forCurrentLocation()
        
        // compose destination MKMapItem
        let destinationPlacemark = MKPlacemark(coordinate: pointAnnotation.coordinate)
        let destination: MKMapItem = MKMapItem(placemark: destinationPlacemark)

        // compose a request
        let mkDirReq: MKDirectionsRequest = MKDirectionsRequest()
        mkDirReq.source = source
        mkDirReq.destination = destination
        print("------------------------------------------------------------------------")
        print(mkDirReq.source)
        print("------------------------------------------------------------------------")
        print( mkDirReq.destination)
        print("------------------------------------------------------------------------")
        
        // ask for directions
        let mkDirections: MKDirections = MKDirections(request: mkDirReq)

        // start semaphore block to synchronize completion handler
        let sem = DispatchSemaphore(value: 0)
        
        print("pre -- mkDirections.calculateETA()")
        mkDirections.calculateETA() {
            (response, error) in
            if let error = error {
                // Insert error handling
                print("-- MapUpdate -- getEtaDistance -- Error: \(error)")
                
                self.eta = nil

                sem.signal()
                
                return

            } else {
                print("-- MapUpdate -- getEtaDistance -- response:" +
                    " \(String(describing: response)))")
                
                self.eta = Int((response?.expectedTravelTime)! / 60)
                
                print("-- MapUpdate -- getEtaDistance -- eta:" +
                    " \(String(describing: self.eta))) min")
                
                // scale per eta and travel method: car, walk
                self.distance = ((response?.distance)! * 3.2808) / 5280

                print("-- MapUpdate -- getEtaDistance -- distance:" +
                    " \(String(describing: self.distance))) miles")
                
                sem.signal()
                
                return
            }
        }
        // got here after sem.signal()
        let semResult: DispatchTimeoutResult = sem.wait(timeout: DispatchTime.init(uptimeNanoseconds: 1000000000000))

        print("semResult: \(semResult)")
        if (semResult == DispatchTimeoutResult.timedOut) {
                self.eta = nil
        }
        return (self.eta, self.distance)
        
    }
    
    func snapView (packet: Location, mapView: MKMapView) {
        
    }
}
