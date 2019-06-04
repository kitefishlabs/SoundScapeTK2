//
//  SoundScape.swift
//  SoundScapeTK2
//
//  Created by kfl on 5/27/19.
//  Copyright © 2019 kfl. All rights reserved.
//

import Foundation
import UIKit
import MapKit

enum FinishRule: String, CustomDebugStringConvertible, Codable {
    case finish
    case cutoff
    var debugDescription: String {
        return rawValue
    }
}

enum RegionState: String, CustomDebugStringConvertible, Codable {
    case ready
    case playing
    case stopping
    case fading     // fading out
    var debugDescription: String {
        return rawValue
    }
}

class Region:Codable {
    
    var id:                 Int = 0
    var shape:              String = "CIRCLE"
    var label:              String = ""
    var lat:                Double = 0.0
    var lon:                Double = 0.0
    var rad:                Double = 0.0
    var lives:              Int = 99
    var loops:              Int?
    var finishRule:         FinishRule?
    var trig:               String = ""
    var attack:             Double = 1000.0
    var release:            Double = 2000.0
    var state:              RegionState?
    var internalDistance:   Double?
    var linkedSoundFile:    String?
    var assignedSlot:       Int?
    var pauseOffset:        Int?
    var startedAt:          Date?
    var active:              Bool?
}

extension Region: Hashable {
    static func == (lhs: Region, rhs: Region) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class RegionPin: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
    }
}
