//
//  ViewController.swift
//  TringPlayeIntegration
//
//  Created by Ravi Chandran on 17/06/24.
//

import UIKit
import AVKit
import TringtvOSPlayer

//"https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
// "https://cdn.jwplayer.com/manifests/YvRgLFCV.m3u8"

class ViewController: UIViewController {



    // "https://cdn.jwplayer.com/manifests/wwLYM8OC.m3u8"

    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var btn1: UIButton!
    @IBOutlet weak var btn2: UIButton!
    @IBOutlet weak var btn3: UIButton!
    var controlsDisplaytimer: Timer?
    private var backGesture: UITapGestureRecognizer?
    // var playerconfig = ConfigBuilder()
    override func viewDidLoad() {
        super.viewDidLoad()
        let tringView = TringPlayerView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        self.view.addSubview(tringView)
        let PlayerItems = [

            PlayerItem(movieTitle: "Minno", thumbnailImg: "https://cdn.jwplayer.com/v2/media/azjHGeTe/poster.jpg?width=1920", videoUrl: "https://cdn.jwplayer.com/manifests/ZDD394m7.m3u8"),
            PlayerItem(movieTitle: "Breaking Bad", thumbnailImg: "https://cdn.jwplayer.com/v2/media/azjHGeTe/poster.jpg?width=1920", videoUrl: "https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8"),
            PlayerItem(movieTitle: "Dark", thumbnailImg: "https://cdn.jwplayer.com/v2/media/qyHWAAgv/poster.jpg?width=320", videoUrl: "http://sample.vodobox.net/skate_phantom_flex_4k/skate_phantom_flex_4k.m3u8"),
            PlayerItem(movieTitle: "F.R.I.E.N.D.S", thumbnailImg: "https://cdn.jwplayer.com/v2/media/gYWlIoqE/poster.jpg?width=720", videoUrl: "https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8")
        ]

        tringView.tringPlayerConfig(items: PlayerItems)
        tringView.addGesturefromController(self)
        tringView.getUIViewController(yourVc: self)
        tringView.playerdelegate = self
    }

}
extension ViewController: PlayerControllerDelegate {
    func videoPlaybackStarted(_ player: PlayerItem) {
        print("Analytics:- videoPlaybackStarted", player)
    }
    func videoContentStarted(_ player: PlayerItem) {
        print("Analytics:- Video content Started")
    }
    func videoContentCompleted(_ player: TringtvOSPlayer.PlayerItem) {
        print("Analytics:- Video content completed")
    }
    func playerHeartbeatRate(at currentTime: TimeInterval, _ player: PlayerItem) {
         print("Analytics: Current playing time \(currentTime)")
    }
    func seekStarted(from startTime: TimeInterval, _ player: TringtvOSPlayer.PlayerItem) {
        print("Analytics: seek started from \(startTime)")
    }
    func seekCompleted(with seekedDuration: TimeInterval, _ player: TringtvOSPlayer.PlayerItem) {
        print("Analytics: seek completed with a duration of \(seekedDuration) seconds")
    }
    func videoTransitionScreenStarted(_ player: TringtvOSPlayer.PlayerItem) {
        print("Analytics:- video Transition Screen Started")
    }
    func videoTransitionCompleted(_ player: PlayerItem) {
        print("Analytics:- video Transition Screen Completed")
    }
    func videoPlaybackCompleted(_ player: PlayerItem) {
        print("Analytics:- Video playback completed")
    }
    func playerController(state: TringtvOSPlayer.TringPlayerState, _ player: TringtvOSPlayer.PlayerItem) {
        switch state{
        case .playing:
            print("Analytics:- Player is playing")
        case .bufferFinished:
            print("Analytics:- Player bufferFinished")
        case .buffering:
            print("Analytics:- Player is buffering")
        case .error:
            print("Analytics:- Player is in error state")
        case .paused:
            print("Analytics:- Player is paused")
        case .resumed:
            print("Analyitcs:- Player is resumed")
        }

    }

    func playerController(currentTime: TimeInterval, totalTime: TimeInterval) {
        print("Analytics:- Current Time \(currentTime), totalTime, \(totalTime)")
    }


}

