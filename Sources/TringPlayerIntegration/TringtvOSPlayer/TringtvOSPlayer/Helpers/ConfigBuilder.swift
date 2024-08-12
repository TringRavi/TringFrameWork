//
//  ConfigBuilder.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 11/06/24.
//

import Foundation
import UIKit
import CoreMedia

public struct ConfigBuilder {
     var  seekInterval = 10.0
     var  upNextInSeconds = 10
     var  showThumbnails = true
     var  showChapter = false
     var  isDVRSupported = false
     var  isUpNextSupported = true
     var  isDRMSupported = false
     var  isAnalyticsSupported = false
     var  isAdSupported = false
     var  isLiveSupported = false
     var  showCustomVideoInfo = false
     var  autoStart = true
     var  hidePlayerControlsin = 5
     var  isCustomPlayer = false
    var  appThemeColor = "#3BBFBE"
    public init() {
    }
}
