//
//  RegionTableViewCell.swift
//  SoundScapeTK2
//
//  Created by kfl on 5/29/19.
//  Copyright © 2019 kfl. All rights reserved.
//

import UIKit

class RegionTableViewCell: UITableViewCell {

    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var labelLabel: UILabel!
    @IBOutlet weak var trigLabel: UILabel!
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var lonLabel: UILabel!
    @IBOutlet weak var radiusLabel: UILabel!
    
    var region: Region? {
        didSet {
            guard let region = region else { return }
            idLabel.text = String(region.id)
            labelLabel.text = region.label
            trigLabel.text = region.trig
            latLabel.text = String(region.lat)
            lonLabel.text = String(region.lon)
            radiusLabel.text = String(region.rad)
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
