//
//  Users.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 6/4/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit

/// User name and location coordinates
///
/// name { get set}
/// longitude { set }
/// latitude { set }

class Users {
    var name: String
    var location: Location
    
    init(name: String) {
        self.name = name
        self.location = Location()
    }
    
    init(name: String, location: Location) {
        self.name = name
        self.location = Location(userName: name, location: location)
    }

    func setName(name: String) {
        self.name = name
    }
    
    func getName() -> String {
        return self.name
    }
    /*
    func setLatitude(latitude: CLLocationDegrees) {
        location.setLatitude(latitude: latitude)
    }
    
    func setLongitude(longitude: CLLocationDegrees) {
        location.setLongitude(longitude: longitude)
    }
    */
    func setLocation(location: Location) {
        self.location.latitude = location.latitude
        self.location.longitude = location.longitude
        
    }
}
