//
//  contentDataModel.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 29/06/24.
//

import Foundation

public struct ContentData {
    var vttUrl: String
    var playerItems = [PlayerItem]()
}

public struct PlayerItem {
    public var movieTitle: String
    public var thumbnailImg: String
    public var videoUrl: String
    public init(movieTitle: String, thumbnailImg: String, videoUrl: String) {
        self.movieTitle = movieTitle
        self.thumbnailImg = thumbnailImg
        self.videoUrl = videoUrl
    }
}
