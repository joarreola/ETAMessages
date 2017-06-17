//
//  Location.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit

/// latitude and longitude location coordinates
///
/// latitude { set }
/// longitude { set }

struct Location {
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?

    init() {
        self.latitude = 0.0
        self.longitude = 0.0
    }

    mutating func setLatitude(latitude: CLLocationDegrees?) {
        self.latitude = latitude
    }
    
    mutating func setLongitude(longitude: CLLocationDegrees?) {
        self.longitude = longitude
    }
}
