//
//  Users.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 6/4/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit

class Users {
    var name: String
    var location: Location = Location()
    
    init(name: String) {
        self.name = name
    }
    
    func setName(name: String) {
        self.name = name
    }
    
    func getName() -> String {
        return self.name
    }
    
    func setLatitude(latitude: CLLocationDegrees) {
        location.setLatitude(latitude: latitude)
    }
    
    func setLongitude(longitude: CLLocationDegrees) {
        location.setLongitude(longitude: longitude)
    }
}
