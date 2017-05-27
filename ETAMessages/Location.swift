//
//  Location.swift
//  ETAMessages
//
//  Created by taiyo on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit

struct Location {
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var remoteLatitude: CLLocationDegrees
    var remoteLongitude: CLLocationDegrees

    init() {
        self.latitude = 0.0
        self.longitude = 0.0
        self.remoteLatitude = 0.0
        self.remoteLongitude = 0.0
    }

    mutating func setLatitude(latitude: CLLocationDegrees) {
        self.latitude = latitude
    }
    
    mutating func setLongitude(longitude: CLLocationDegrees) {
        self.longitude = longitude
    }
    
    mutating func setRemoteLatitude(latitude: CLLocationDegrees) {
        self.remoteLatitude = latitude
    }
    
    mutating func setRemoteLongitude(longitude: CLLocationDegrees) {
        self.remoteLongitude = longitude
    }
}
