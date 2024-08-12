//
//  MetaDataOptions.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 21/06/24.
//

import Foundation
import AVKit

class SubtitleModel {
    var title: String
    var isEmbbeded: Bool
   // var audioOptions: AVMediaSelectionOption?
    required public init(title: String, isEmbbeded: Bool) {
        self.title = title
        self.isEmbbeded = isEmbbeded
    }
}
