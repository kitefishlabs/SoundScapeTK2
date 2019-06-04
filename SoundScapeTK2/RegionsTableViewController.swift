//
//  RegionsViewController.swift
//  SoundScapeTK2
//
//  Created by kfl on 5/28/19.
//  Copyright © 2019 kfl. All rights reserved.
//

import UIKit

class RegionsTableViewController: UITableViewController {

    var soundscapeData: SoundScapeData?
    
    var regions: [Region] {
        return soundscapeData?.regions ?? []
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.regions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegionCell", for: indexPath) as! RegionTableViewCell
        let region = self.regions[indexPath.row]
        cell.region = region
        return cell
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        getJSONTestData()
//    }
}
