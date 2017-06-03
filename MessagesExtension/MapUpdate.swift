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

struct PointAnnotations {
    var pointAnnotation: MKPointAnnotation?
}

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
    public var pointAnnotationStruct = PointAnnotations()
    
    func showRemote (packet: Location, mapView: MKMapView) {
        
    }

    //func addPin (packet: Location, mapView: MKMapView, _ remove: Bool) -> MKPointAnnotation {
    func addPin (packet: Location, mapView: MKMapView, _ remove: Bool) {
    
        print("-- MapUpdate -- addPin: add pin for remoteUser")
    
        self.locLatitude  = packet.latitude
        self.locLongitude = packet.longitude
        self.remLatitude  = packet.remoteLatitude
        self.remLongitude = packet.remoteLongitude
        let pointAnnotation: MKPointAnnotation
        
        pointAnnotation = MKPointAnnotation()
        
        if pointAnnotationStruct.pointAnnotation != nil {
            mapView.removeAnnotation(pointAnnotationStruct.pointAnnotation!)
            print("-- MapUpdate -- addPin -- removed pointAnnotation: \(String(describing: pointAnnotationStruct.pointAnnotation))")
        }
            
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: remLatitude,
                                                            longitude: remLongitude)
            
        pointAnnotationStruct.pointAnnotation = pointAnnotation

        if remove {
            print("-- MapUpdate -- addPin -- removed pointAnnotation: \(pointAnnotation)")
        } else {
            mapView.addAnnotation(pointAnnotation)
        
            print("-- MapUpdate -- addPin -- added pointAnnotation: \(pointAnnotation)")
        }
            
        return
    }

    func centerView (packet: Location, mapView: MKMapView) -> CLLocationCoordinate2D {
        print("-- MapUpdate -- centerView: center mapView between local and remote users")
    
        let lLat  = packet.latitude
        let lLong = packet.longitude
        let rLat  = packet.remoteLatitude
        let rLong = packet.remoteLongitude
        var centerLatitude: CLLocationDegrees
        var centerLongitude: CLLocationDegrees
        let center: CLLocationCoordinate2D

        print("-- MapUpdate -- centerView -- lLat: \(lLat)  lLong: \(lLong) rLat: \(rLat) rLong: \(rLong)")

        (lLat < rLat) ? (latDistTo = lLat.distance(to: rLat) / 2) :
                        (latDistTo = rLat.distance(to: lLat) / 2)
        (lLong < rLong) ? (lngDistTo = lLong.distance(to: rLong) / 2) :
                        (lngDistTo = rLong.distance(to: lLong) / 2)
        
        print("-- MapUpdate -- centerView -- latDistTo: \(latDistTo) lngDistTo: \(lngDistTo)")
        
        (lLat > rLat) ? (centerLatitude = rLat + latDistTo) :
            (centerLatitude = lLat + latDistTo)

        // negative longitudes
        (lLong > rLong) ? (centerLongitude = rLong + lngDistTo) :
            (centerLongitude = lLong + lngDistTo)
        
        print("-- MapUpdate -- centerView -- centerLatitude: \(centerLatitude) centerLongitude: \(centerLongitude)")

        center = CLLocationCoordinate2D(latitude: centerLatitude,
                                            longitude: centerLongitude)
        
        mapView.setCenter(center, animated: true)
    
        return center
        
    }

    func snapView (packet: Location, mapView: MKMapView) {
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blue
        return renderer
    }
}
