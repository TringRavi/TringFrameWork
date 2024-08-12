//
//  SettingsPlayerTableViewCell.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 20/06/24.
//

import UIKit

class SettingsPlayerTableViewCell: UITableViewCell {
    @IBOutlet weak var tickImg: UIImageView!
    @IBOutlet weak var selectingLbl: UILabel!
    override var frame: CGRect {
            get {
                return super.frame
            }
            set (newFrame) {
                var frame = newFrame
                frame.origin.x += 0
                frame.size.width = newFrame.size.width + 120
                super.frame = frame
            }
        }
}
