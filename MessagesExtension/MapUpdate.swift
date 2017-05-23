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

    func showRemote (packet: Location, mapView: MKMapView) {
        
    }

    func addPin (packet: Location, mapView: MKMapView) {
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
    
    func getEtaDistance (packet: Location, mapView: MKMapView) {
    
    }
    
    func snapView (packet: Location, mapView: MKMapView) {
        
    }
}
