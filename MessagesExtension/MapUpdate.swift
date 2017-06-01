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
            
        //return pointAnnotation
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

        latDistTo = lLat.distance(to: rLat) / 2
        lngDistTo = lLong.distance(to: rLong) / 2
        
        (lLat > rLat) ? (centerLatitude = rLat + latDistTo) :
            (centerLatitude = lLat + latDistTo)

        // negative longitudes
        (lLong < rLong) ? (centerLongitude = rLong + lngDistTo) :
            (centerLongitude = lLong + lngDistTo)
        
        center = CLLocationCoordinate2D(latitude: centerLatitude,
                                            longitude: centerLongitude)
        
        mapView.setCenter(center, animated: true)
    
        return center
        
    }

    //func getEtaDistance (packet: Location, mapView: MKMapView, display: UILabel,
    //                     etaPointer: UnsafeMutableRawPointer) -> (eta: TimeInterval?, distance: Double) {
    func getEtaDistance (packet: Location, mapView: MKMapView, display: UILabel,
                         etaPointer: UnsafeMutableRawPointer) {

        print("-- MapUpdate -- getEtaDistance: get eta from local to remote device," +
                    " and travel distance between devices")
    
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
                
                print("-- MapUpdate -- mkDirections.calculate -- Error: \(String(describing: error))")
                
                self.eta = nil

                return
            }
            
            for route in unwrappedResponse.routes {
                //mapView.add(route.polyline)
                //mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
    
                print("-- MapUpdate -- mkDirections.calculate -- closure -- Distance: \(route.distance) meters")
                print("-- MapUpdate -- mkDirections.calculate -- closure -- ETA: \(route.expectedTravelTime) sec")

                self.eta = route.expectedTravelTime
                self.distance = route.distance * 3.2808
                print("-- MapUpdate -- mkDirections.calculate -- closure -- self.distance: \(self.distance) feet")
                print("-- MapUpdate -- mkDirections.calculate -- closure -- self.eta: \(self.eta!)) sec")
                
                for step in route.steps {
                    print(step.instructions)
                }
            // MARK:
                // FIXME: Do linear-regression
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
                print("-- MapUpdate -- mkDirections.calculate -- closure -- delta: \(delta)")
                
                let center = self.centerView(packet: packet, mapView: mapView)

                let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(delta),
                                                              longitudeDelta: CLLocationDegrees(delta))
                
                let region = MKCoordinateRegion(center: center, span: span)
                
                print("-- MapUpdate -- mkDirections.calculate -- closure -- re-span mapView...")
                
                mapView.setRegion(region, animated: true)
                
                // display locPacket
                display.text = ""
                display.text =
                    "local:\t\t( \(packet.latitude),\n\t\t\t\(packet.longitude) )\n" +
                    "remote:\t( \(packet.remoteLatitude),\n\t\t\t\(packet.remoteLongitude) )\n" +
                    "eta:\t\t\((self.eta!)) sec\n" +
                    "distance:\t\((self.distance)) ft"
                
                // check etaPointer
                var x = etaPointer.load(as: TimeInterval.self)
                print("-- MapUpdate -- mkDirections.calculate -- closure -- etaPointer: \(x)")
                
                // set
                if self.eta != nil {
                    let etaValue = self.eta!
                    etaPointer.storeBytes(of: etaValue, as: TimeInterval.self)
                    print("-- MapUpdate -- mkDirections.calculate -- closure -- updated etaPointer")
                }
                x = etaPointer.load(as: TimeInterval.self)
                print("-- MapUpdate -- mkDirections.calculate -- closure -- etaPointer: \(x)")
                
    
            // MARK:-
            }
            
            return
        }
        print("-- MapUpdate -- mkDirections.calculate -- returning after closure")
        //return (self.eta, self.distance)
        return

    }

    func snapView (packet: Location, mapView: MKMapView) {
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blue
        return renderer
    }
}
