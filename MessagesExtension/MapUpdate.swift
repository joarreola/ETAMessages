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
    
    init() {
        self.pointAnnotation = nil
    }
}

class MapUpdate {
    static var pointAnnotationStruct: PointAnnotations = PointAnnotations()

    func addPin (packet: Location, mapView: MKMapView, remove: Bool) {
    
        print("-- MapUpdate -- addPin: add pin for remoteUser")
    
        let pointAnnotation: MKPointAnnotation
        
        pointAnnotation = MKPointAnnotation()
        
        if MapUpdate.pointAnnotationStruct.pointAnnotation != nil {
            print("-- MapUpdate -- addPin -- removing pointAnnotation: \(String(describing: MapUpdate.pointAnnotationStruct.pointAnnotation))")
            
            mapView.removeAnnotation(MapUpdate.pointAnnotationStruct.pointAnnotation!)

        }
            
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: packet.latitude,
                                                            longitude: packet.longitude)
        
        MapUpdate.pointAnnotationStruct.pointAnnotation = pointAnnotation

        if remove {
            print("-- MapUpdate -- addPin -- removed pointAnnotation: \(pointAnnotation)")
        } else {
            mapView.addAnnotation(pointAnnotation)
        
            print("-- MapUpdate -- addPin -- added pointAnnotation: \(pointAnnotation)")
        }
            
        return
    }

    func centerView (localpacket: Location, mapView: MKMapView) -> CLLocationCoordinate2D {
        print("-- MapUpdate -- centerView: center mapView on local user")
        
        var center: CLLocationCoordinate2D
        
        print("-- MapUpdate -- centerView -- lLat: \(localpacket.latitude)  lLong: \(localpacket.longitude)")
        
        print("-- MapUpdate -- centerView -- centerLatitude: \(localpacket.latitude) centerLongitude: \(localpacket.longitude)")
            
        center = CLLocationCoordinate2D(latitude: localpacket.latitude,
                                            longitude: localpacket.longitude)
            
        mapView.setCenter(center, animated: true)
            
        return center
            
    }
    
    func centerView (localpacket: Location, remotePacket: Location, mapView: MKMapView) -> CLLocationCoordinate2D {
        print("-- MapUpdate -- centerView: center mapView between local and remote users")
    
        var centerLatitude: CLLocationDegrees
        var centerLongitude: CLLocationDegrees
        var center: CLLocationCoordinate2D
        let latDistTo: CLLocationDegrees
        let lngDistTo: CLLocationDegrees

        print("-- MapUpdate -- centerView -- lLat: \(localpacket.latitude)  lLong: \(localpacket.longitude) rLat: \(remotePacket.latitude) rLong: \(remotePacket.longitude)")

        if remotePacket.latitude == 0.0 {
            print("-- MapUpdate -- centerView -- centerLatitude: \(localpacket.latitude) centerLongitude: \(localpacket.longitude)")
            
            center = CLLocationCoordinate2D(latitude: localpacket.latitude,
                                            longitude: localpacket.longitude)

            mapView.setCenter(center, animated: true)

            return center
            
        }
        
        // for local and remote location pairs
        (localpacket.latitude < remotePacket.latitude) ?
                (latDistTo = localpacket.latitude.distance(to: remotePacket.latitude) / 2) :
                (latDistTo = remotePacket.latitude.distance(to: localpacket.latitude) / 2)

        (localpacket.longitude < remotePacket.longitude) ?
                (lngDistTo = localpacket.longitude.distance(to: remotePacket.longitude) / 2) :
                (lngDistTo = remotePacket.longitude.distance(to: localpacket.longitude) / 2)
        
        print("-- MapUpdate -- centerView -- latDistTo: \(latDistTo) lngDistTo: \(lngDistTo)")
        
        (localpacket.latitude > remotePacket.latitude) ?
            (centerLatitude = remotePacket.latitude + latDistTo) :
            (centerLatitude = localpacket.latitude + latDistTo)

        // negative longitudes
        (localpacket.longitude > remotePacket.longitude) ?
            (centerLongitude = remotePacket.longitude + lngDistTo) :
            (centerLongitude = localpacket.longitude + lngDistTo)
        
        print("-- MapUpdate -- centerView -- centerLatitude: \(centerLatitude) centerLongitude: \(centerLongitude)")

        center = CLLocationCoordinate2D(latitude: centerLatitude,
                                            longitude: centerLongitude)
        
        mapView.setCenter(center, animated: true)
    
        return center
        
    }
    
    func refreshMapView(packet: Location, mapView: MKMapView, eta: EtaAdapter) {
        print("-- MapUpdate -- refreshMapView: refresh mapView for local coordinates")
        
        let delta: Float = 0.1
        
        // center mapView on single, local coordinates
        let center = self.centerView(localpacket: packet, mapView: mapView)
        
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(delta),
                                                      longitudeDelta: CLLocationDegrees(delta))
        
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(region, animated: true)
        
    }
    
    func refreshMapView(localPacket: Location, remotePacket: Location,
                        mapView: MKMapView, eta: EtaAdapter) {
        print("-- MapUpdate -- refreshMapView: refresh mapView for local and remote coordinates")

        let delta: Float
        
        // center coordinates between devices or single local coordinates
        let center = self.centerView(localpacket: localPacket, remotePacket: remotePacket,
                                     mapView: mapView)
// MARK:
        // FIXME: center mapView without eta.distance data
        // compute delta based on distance
        if eta.distance == nil || remotePacket.latitude == 0.0 {

            print("-- MapUpdate -- refreshMapView -- hardcoding delta to 0.1")
    
            delta = 0.1
            
        } else {
        // FIXME: Do linear-regression
            // compute a delta to reset the span. Use switch for now
            let distance = eta.distance!

            print("-- MapUpdate -- refreshMapView -- distance: \(distance)")

            switch distance {
                
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
                
            case 1000..<2000:
                
                delta = 0.006
            
            case 2000..<3000:
                
                delta = 0.007
                
            case 3000..<4000:
                
                delta = 0.009
    
            case 4000..<5000:
                
                delta = 0.01
                
            case 5000..<7000:
                
                delta = 0.01
                
            case 7000..<10000:
                
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
            print("-- MapUpdate -- refreshMapView -- delta: \(delta)")
        }
// MARK:-

        // span
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(delta),
                                                      longitudeDelta: CLLocationDegrees(delta))

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
