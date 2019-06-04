//
//  SoundScapeData.swift
//  SoundScapeTK2
//
//  Created by kfl on 5/27/19.
//  Copyright © 2019 kfl. All rights reserved.
//

import Foundation
import UIKit

// Manages regions, loading regions from json, hit-testing
class SoundScapeData {

    let testURL = "https://my-json-server.typicode.com/kitefishlabs/json-test-data/regions"
    
    var regions = [Region]()
    
    func getJSONTestData() {
        
        let urlRequest = URLRequest(url: RegionsResource().url)
        
        let task = URLSession.shared.dataTask(
            with: urlRequest)
        {(data, response, error) -> Void in
            
            // check for any errors
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error!)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
            do {
                let model = try JSONDecoder().decode([Region].self, from:responseData)
                print(model)
                for reg in model {
                    self.regions.append(reg)
                }
                for i in 0...(self.regions.count - 1) {
                    self.regions[i].internalDistance = 0.0
                    self.regions[i].state = .ready
                    self.regions[i].finishRule = .cutoff
                    self.regions[i].linkedSoundFile = Bundle.main.bundlePath + "/" + self.regions[i].trig
                    print("setting full path: ", (Bundle.main.bundlePath + "/" + self.regions[i].trig))
                    self.regions[i].assignedSlot = nil
                    self.regions[i].pauseOffset = nil
                    self.regions[i].startedAt = nil
                    self.regions[i].active = true
                }
//                DispatchQueue.main.async { regionsVC.tableView.reloadData() }
                
            } catch let parsingError{
                print("Error", parsingError)
            }
            
        }
        task.resume()
    }
    
    // returns hit-test result, distance to center, internal distance (normalized)
    func hitTestRegion (region:Region, lat:Double, lon:Double) -> (Bool,Double,Double) {
        switch region.shape {
        case "CIRCLE":
            let dist = sqrt(pow((lat - region.lat), 2.0) + pow((lon - region.lon), 2.0))
            return ((dist <= region.rad), dist, (dist / region.rad))
        default:
            return (false,0.0, 0.0)
        }
    }
    
    // naively iterate through ALL regions and hit-test each
    func testAllRegions (lat: Double, lon: Double) -> [Region] {
        var res = [Region]()
        for reg in self.regions {
            let (hit,dist,cdist) = self.hitTestRegion(region: reg, lat: lat, lon: lon)
            print("hit: " + String(hit) + " dist: " + String(dist) + " cdist: " + String(cdist))
            if hit {
                res.append(reg)
            }
            print(res)
        }
        return res
    }
}
