//
//  MusicTableViewCell.swift
//  WF
//
//  Created by Bo Ni on 7/1/18.
//  Copyright © 2018 Bo Ni. All rights reserved.
//

import UIKit

class MusicTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var musicNameLabel: UILabel!
    @IBOutlet weak var producerLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
