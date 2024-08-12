//
//  AdsPlayerView.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 03/07/24.
//

import UIKit
import GoogleInteractiveMediaAds

protocol AdsPlayerController: AnyObject {
    func showAdsView(isHide: Bool)
    func getCuePoints(cueArray: [Any])
    func getAdsLoader(adsLoader: IMAAdsLoader)
    func allAdsCompleted()
}

class AdsPlayerView: UIView, IMAAdsLoaderDelegate {
    var adsLoader: IMAAdsLoader!
    var adsManager: IMAAdsManager!
    var contentPlayhead: IMAAVPlayerContentPlayhead?
    var adContainerViewController: UIViewController?
    private var adsView: UIView!
    let nibName: String = "AdsPlayerView"
    weak var adPlayerDelegate: AdsPlayerController?
    static let AdTagURLString = """
    https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/vmap_ad_samples&sz=640x480& \
    cust_params=sample_ar%3Dpremidpost&ciu_szs=300x250&gdfp_req=1&ad_rule=1&output=vmap& \
    unviewed_position_start=1&env=vp&impl=s&cmsid=496&vid=short_onecue&correlator=
    """
    override init(frame: CGRect) {
        super.init(frame: frame)
//        commonInit()
//        setUpAdsLoader()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpAdsLoader()
    }
    fileprivate func commonInit() {
        self.adsView = UINib(
            nibName: self.nibName,
            bundle: Bundle(for: type(of: self))).instantiate(
                withOwner: self, options: nil
            )[0] as? UIView
        self.adsView.frame = bounds
        self.adsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(adsView)
    }
    func setUpAdsLoader() {
        adsLoader = IMAAdsLoader(settings: nil)
        adsLoader.delegate = self
      }
    func requestAds(adContainerViewController: UIViewController, player: AVPlayer) {
        DispatchQueue.main.async {[weak self] in
            self?.contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: (player))
            let adDisplayContainer = IMAAdDisplayContainer(
                adContainer: self!,
                viewController: adContainerViewController
            )
            // Create an ad request with our ad tag, display container, and optional user context.
            let request = IMAAdsRequest(
                adTagUrl: AdsPlayerView.AdTagURLString,
                adDisplayContainer: adDisplayContainer,
                contentPlayhead: self?.contentPlayhead,
                userContext: nil)
            self?.adsLoader.requestAds(with: request)
        }
      }
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        print("adsLoadedWith")
        adsManager = adsLoadedData.adsManager
        adsManager.initialize(with: nil)
        adsManager.delegate = self
        adPlayerDelegate?.getAdsLoader(adsLoader: adsLoader)
        adPlayerDelegate?.getCuePoints(cueArray: adsManager.adCuePoints)
    }
    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        adPlayerDelegate?.showAdsView(isHide: false)
    }
}
extension AdsPlayerView: IMAAdsManagerDelegate {
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // Pause the content for the SDK to play ads.

        adPlayerDelegate?.showAdsView(isHide: true)
        print("adsManagerDidRequestContentPause")
    }
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        // Resume the content since the SDK is done playing ads (at least for now).
        adPlayerDelegate?.showAdsView(isHide: false)
        print("adsManagerDidRequestContentResume")
    }
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        if event.type == IMAAdEventType.LOADED {
              adsManager.start()
            }
        if event.type == IMAAdEventType.ICON_TAPPED {
            print("ADS_CLICKED")
        }
        if event.type == IMAAdEventType.TAPPED {
            print("ADS_TAPPED")
        }
        if event.type == IMAAdEventType.RESUME {
            print("ADS_RESUME")
        }
        if event.type == IMAAdEventType.ICON_FALLBACK_IMAGE_CLOSED {
            adsManager.resume()
        }
        if event.type == IMAAdEventType.ALL_ADS_COMPLETED {
            adPlayerDelegate?.allAdsCompleted()
        }
    }
    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        // if there is any error related to ads need to remove the ads layer and show our tringplayer view
    }
}
