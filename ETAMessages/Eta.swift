//
//  Eta.swift
//  ETAMessages
//
//  Created by taiyo on 5/31/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation

class Eta {
    var etaPointer: UnsafeMutableRawPointer
    var eta: TimeInterval?
    
    init() {
        print("-- Eta -- init")
        self.eta = 0.0
        self.etaPointer = UnsafeMutableRawPointer.allocate(bytes: 64, alignedTo: 1)
        self.etaPointer.bindMemory(to: TimeInterval.self, capacity: 64)
        //self.etaPointer.initializeMemory(as: TimeInterval.self, count: 64, to: 0.0)
        self.etaPointer.storeBytes(of: 0.0, as: TimeInterval.self)

    }
    
    func loadPointer(data: TimeInterval) {
        self.etaPointer.storeBytes(of: data, as: TimeInterval.self)
    }
    
    func deallocatePointer() {
        self.etaPointer.deallocate(bytes: 64, alignedTo: 8)
    }
    
    func loadPointer() -> TimeInterval {
        let x = self.etaPointer.load(as: TimeInterval.self)
        
        return x
    }
    
    func setEta(eta: TimeInterval) {
        self.eta = eta
    }
    
    func getEta() -> TimeInterval {
        return self.eta!
    }
}
