//
//  PlayerControllerListeners.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 09/08/24.
//

import Foundation
import AVKit
public protocol PlayerControllerDelegate: AnyObject{
    func playerController(state: TringPlayerState, _ mediaObject: PlayerItem)
    func playerHeartbeatRate(at currentTime: TimeInterval, _ mediaObject: PlayerItem) // Current playing time 1200.000067304
    func seekStarted(from startTime: TimeInterval, _ mediaObject: PlayerItem) // started
    func seekCompleted(with seekedDuration: TimeInterval, _ mediaObject: PlayerItem) // seek completed with a duration of 1229.0 seconds
    func videoTransitionScreenStarted(_ mediaObject: PlayerItem) // video Transition Screen Started
    func videoTransitionCompleted(_ mediaObject: PlayerItem) // video Transition Screen Completed
    func videoPlaybackCompleted(_ mediaObject: PlayerItem)
    func videoPlaybackStarted(_ mediaObject: PlayerItem) // Video playback started
    func videoContentStarted(_ mediaObject: PlayerItem) // Video content started
    func videoContentCompleted(_ mediaObject: PlayerItem) // Video content completed
    //func playerHeartbeat
}

public enum TringPlayerState {
    case buffering
    case bufferFinished
    case paused // player is paused
    case error
    case playing // // Player is playing
    case resumed // Player is resumed
}
