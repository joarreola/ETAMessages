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
    public var pointAnnotationStruct = PointAnnotations()

    //func addPin (packet: Location, mapView: MKMapView, _ remove: Bool) -> MKPointAnnotation {
    func addPin (packet: Location, mapView: MKMapView, remove: Bool) {
    
        print("-- MapUpdate -- addPin: add pin for remoteUser")
    
        let pointAnnotation: MKPointAnnotation
        
        pointAnnotation = MKPointAnnotation()
        
        if pointAnnotationStruct.pointAnnotation != nil {
            mapView.removeAnnotation(pointAnnotationStruct.pointAnnotation!)
            print("-- MapUpdate -- addPin -- removed pointAnnotation: \(String(describing: pointAnnotationStruct.pointAnnotation))")
        }
            
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: packet.remoteLatitude,
                                                            longitude: packet.remoteLongitude)
            
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
    
        var centerLatitude: CLLocationDegrees
        var centerLongitude: CLLocationDegrees
        var center: CLLocationCoordinate2D
        let latDistTo: CLLocationDegrees
        let lngDistTo: CLLocationDegrees

        print("-- MapUpdate -- centerView -- lLat: \(packet.latitude)  lLong: \(packet.longitude) rLat: \(packet.remoteLatitude) rLong: \(packet.remoteLongitude)")

        if packet.remoteLatitude == 0.0 {
            print("-- MapUpdate -- centerView -- centerLatitude: \(packet.latitude) centerLongitude: \(packet.longitude)")
            
            center = CLLocationCoordinate2D(latitude: packet.latitude,
                                            longitude: packet.longitude)

            mapView.setCenter(center, animated: true)

            return center
            
        }
        
        // for local and remote location pairs
        (packet.latitude < packet.remoteLatitude) ?
                (latDistTo = packet.latitude.distance(to: packet.remoteLatitude) / 2) :
                (latDistTo = packet.remoteLatitude.distance(to: packet.latitude) / 2)

        (packet.longitude < packet.remoteLongitude) ?
                (lngDistTo = packet.longitude.distance(to: packet.remoteLongitude) / 2) :
                (lngDistTo = packet.remoteLongitude.distance(to: packet.longitude) / 2)
        
        print("-- MapUpdate -- centerView -- latDistTo: \(latDistTo) lngDistTo: \(lngDistTo)")
        
        (packet.latitude > packet.remoteLatitude) ?
            (centerLatitude = packet.remoteLatitude + latDistTo) :
            (centerLatitude = packet.latitude + latDistTo)

        // negative longitudes
        (packet.longitude > packet.remoteLongitude) ?
            (centerLongitude = packet.remoteLongitude + lngDistTo) :
            (centerLongitude = packet.longitude + lngDistTo)
        
        print("-- MapUpdate -- centerView -- centerLatitude: \(centerLatitude) centerLongitude: \(centerLongitude)")

        center = CLLocationCoordinate2D(latitude: centerLatitude,
                                            longitude: centerLongitude)
        
        mapView.setCenter(center, animated: true)
    
        return center
        
    }
    
    func refreshMapView(packet: Location, mapView: MKMapView, delta: Double) {
        print("-- MapUpdate -- refreshMapView: refresh mapView -- delta: \(delta)")

            
        let center = self.centerView(packet: packet, mapView: mapView)

        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: delta,
                                                      longitudeDelta: delta)

        let region = MKCoordinateRegion(center: center, span: span)

        mapView.setRegion(region, animated: true)

    }
    
    func displayUpdate(display: UILabel, stringArray: [String]) {
        print("-- MapUpdate -- displayUpdate")
        
        display.text = ""
        
        for string in stringArray {
            display.text =  display.text! + string
        }
    }

    /*
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blue
        return renderer
    }
    */
}
