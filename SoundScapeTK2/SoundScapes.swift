//
//  SoundScape.swift
//  SoundScapeTK2
//
//  Created by kfl on 5/27/19.
//  Copyright © 2019 kfl. All rights reserved.
//

import Foundation

enum FinishRule: String, CustomDebugStringConvertible, Codable {
    case finish
    case cutoff
    var debugDescription: String {
        return rawValue
    }
}

enum RegionState: String, CustomDebugStringConvertible, Codable {
    case unloaded
    case ready
    case playing
    case fading     // fading out
    case stopped
    var debugDescription: String {
        return rawValue
    }
}


struct Region:Codable {
    var id:                 Int
    var shape:              String
    var label:              String
    var lat:                Double
    var lon:                Double
    var rad:                Double
    var lives:              Int
    var loops:              Int?
    var finishRule:         FinishRule?
    var trig:               String
    var attack:             Double
    var release:            Double
    var state:              RegionState?
    var internalDistance:   Double?
}

struct SoundScape {
    var name: String?
    var author: String?
    var regions: [Region]
}
