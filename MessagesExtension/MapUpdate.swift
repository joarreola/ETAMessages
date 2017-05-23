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

    func showRemote (packet: Location, mapView: MKMapView) {
        
    }

    func addPin (packet: Location, mapView: MKMapView) {
        print("-- MapUpdate -- addPin: add pin for remoteUser\n")
    
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
        
    }
    
    func getEtaDistance (packet: Location, mapView: MKMapView) {
    
    }
    
    func snapView (packet: Location, mapView: MKMapView) {
        
    }
}
