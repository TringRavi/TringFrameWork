//
//  TringPlayerView.swift
//  TringPlayer
//
//  Created by Ravi Chandran on 15/06/24.
//

import UIKit
import AVKit
import GoogleInteractiveMediaAds
// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
open class TringPlayerView: UIView, SliderDelegate {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var subtitleView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var slider: TvOSSlider!
    @IBOutlet weak var totalDurationLbl: UILabel!
    @IBOutlet weak var playerControlsView: UIView!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var subtitleBtn: UIButton!
    @IBOutlet weak var audioBtn: UIButton!
    @IBOutlet weak var infoBtn: UIButton!
    @IBOutlet weak var adsView: AdsPlayerView!
    @IBOutlet weak var subtitleOuterView: UIView!
    @IBOutlet weak var audioOuterview: UIView!
    @IBOutlet weak var playPauseImgView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var gradientBGView: UIView!
    @IBOutlet weak var languageImgView: UIImageView!
    @IBOutlet weak var subtitleImgView: UIImageView!
    @IBOutlet weak var infoImgView: UIImageView!
    @IBOutlet weak var settingsBtnsStackView: UIStackView!
    @IBOutlet weak var infoOuterView: UIView!
    @IBOutlet weak var movieTitleLbl: UILabel!
    internal var viewToFocus: UIView?
    var totalDuration: CMTime?
    var playerItemObservation: NSKeyValueObservation?
    var isUserTapsBackFromUpcomingView = false
    var adMarkerview = UIView()
    var player: AVPlayer?
    var playerQueue: AVPlayerItem?
    var playerLayer: AVPlayerLayer?
    var timeObserver: Any?
    var previousMinute = -1
    var seekCount = 0
    var isVTTSubtitleSelected = false
    var selectedSubtileLanguage: String? = nil
    var seekStartingPosition = 0.0
    private var playerQueueBufferEmptyObserver: NSKeyValueObservation?
    private var playerQueueBufferAlmostThereObserver: NSKeyValueObservation?
    var isUpNextClickedCalled = false
    var adLoader: IMAAdsLoader?
    public var configBuilder = ConfigBuilder()
    private var audioOptions: [String]?
    var controlsDisplaytimer: Timer?
    var playPauseTimer: Timer?
    let nibName: String = "TringPlayerView"
    var view: UIView!
    private var selectedSubtitle = 0
    private var selectedAudio = 0
    var subtitles: [String: VTTParser] = [:]
    var subtitle: VTTParser?
    var trickPlayParser: TrickPlayParser?
    var wrappedPlayerItem: PlayerItem?
    var currentPlayingObject: PlayerItem!
    public weak var playerdelegate: PlayerControllerDelegate?
    var upComingList = [PlayerItem]()
    var isSeeking = false
    var showEmbededTrickplay = false
    var isUpCmingViewInitiated = false
    var trickPlayImagesLoaded = false
    open var adContainerController: UIViewController?
    var times = [CMTime]()
    var storeTrickPlayImg = [UIImage]()
    var desiredSecondsReached = true
    var myPreferredFocusedView: UIView?
    var subtitleArr = [SubtitleModel]()
    var subtitleCodeArr = [String]()
    var audioArr = [String]()
    var audioCodeArr = [String]()
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    // If we are assign this view to the storyboard, At that time this Method will gets called
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    deinit {
        print("TringPlayerView is deinitialized")
        controlsDisplaytimer?.invalidate()
        controlsDisplaytimer = nil
        playerQueueBufferEmptyObserver = nil
        playerQueueBufferAlmostThereObserver = nil
        playPauseTimer?.invalidate()
        playPauseTimer = nil
        NotificationCenter.default.removeObserver(self)
    }
    // This need not to be accessed from externally
    fileprivate func commonInit() {
        self.view = UINib(
            nibName: self.nibName,
            bundle: Bundle(for: type(of: self))).instantiate(
                withOwner: self,
                options: nil)[0] as? UIView
        self.view.frame = bounds
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(view)
    }
    // MARK: - AVPlayer Functionalities
    open func tringPlayerConfig(items: [PlayerItem]) {
        if let url = URL(string: items.first?.videoUrl ?? "") {
            player = AVPlayer(url: url)
            setupPlayerLayer()
            activityIndicator.startAnimating()
            guard let playerItem = items.first else{return}
            currentPlayingObject = playerItem
            doAsyncOperationfrom(videourl: items.first?.videoUrl ?? "")
            view.bringSubviewToFront(gradientBGView)
            view.bringSubviewToFront(contentView)
            view.bringSubviewToFront(playPauseImgView)
            view.bringSubviewToFront(activityIndicator)
            addSubtitle(for: "Hindi", vttFile: "https://cdn.jwplayer.com/tracks/jShiK84H.srt")
            addSubtitle(for: "Malayalam", vttFile: "https://cdn.jwplayer.com/tracks/cCc2gMJh.vtt")
           // subtitle = VTTParser(vttUrl: URL(string: "https://cdn.jwplayer.com/tracks/cCc2gMJh.vtt")!)
            slider.maximumTrackTintColor = UIColor.gray
            // updateVideoDuration()
            slider.sliderDelegate = self

            // getInfoFromM3U8(videoUrl: items.first?.videoUrl ?? "")
            movieTitleLbl.text = items.first?.movieTitle
            player?.play()
            setupGestureRecognizers()

        }
        if configBuilder.isAdSupported == true {
            showAdsView()
            self.view.bringSubviewToFront(adsView)
        }
        checkControlsTimerOperation()
        upComingList = items
        // After the 0th index starts to play,Im removing the 0th index and appending it to last
        upComingList.removeFirst()
        upComingList.append(items.first!)
        dowloadTrickPlayImg(trickplayUrl: "https://assets-jpcust.jwpsrv.com/strips/wwLYM8OC-120.jpg")
        overridebackBtn()
        activityIndicator.color = UIColor(hexString: configBuilder.appThemeColor, alpha: 1.0)
        addPlayerobservers()
        gradientBGView.applyGradient(to: gradientBGView)
    }
    func addSubtitle(for language: String, vttFile: String) {
        let parser = VTTParser(vttUrl: URL(string: vttFile)!)
        subtitles[language] = parser
    }
    func doAsyncOperationfrom(videourl: String) {
        Task {
            do {
                let duration = try await fetchVideoDuration()
                await fetchPlayerAssets(videoUrl: videourl)
                totalDuration = duration
                playerdelegate?.videoPlaybackStarted(currentPlayingObject!)
                playerdelegate?.videoContentStarted(currentPlayingObject!)
                slider.isHidden = false
                getInfoFromM3U8(videoUrl: videourl)
                sliderConfigurations()
            } catch {
                print("Failed to get video duration: \(error)")
            }
        }
    }
    func fetchVideoDuration() async throws -> CMTime {
        guard let player = player,
              let asset = player.currentItem?.asset else {
            throw NSError(
                domain: "VideoPlayerError", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Player or asset not available"]
            )
        }
        let duration = try await asset.load(.duration)
        return duration
    }
    private func addPlayerobservers() {
        playerQueueBufferAlmostThereObserver = player?.currentItem?.observe(\.isPlaybackBufferFull, options: [.new]) {
            [weak self] (_, _) in
            self?.playerdelegate?.playerController(state: .bufferFinished, (self?.currentPlayingObject!)!)
            print("buffering is hidden...")
        }
        playerQueueBufferEmptyObserver = player?.currentItem?.observe(\.isPlaybackBufferEmpty, options: [.new]) {
            [weak self] (_, _) in
            self?.playerdelegate?.playerController(state: .buffering, (self?.currentPlayingObject!)!)
            print("buffering...")
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)

    }
    func addBufferObservation() {
        let playbackLikelyToKeepUp = player?.currentItem?.isPlaybackLikelyToKeepUp
        if playbackLikelyToKeepUp == false {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        } else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
        }
    }
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        print("playerItemDidReachEnd")
        playerdelegate?.videoContentCompleted(currentPlayingObject)
        if configBuilder.isUpNextSupported == true {
            upNextClicked(index: 0)
        }
    }
    open func customPlayerConfig(videoUrl: String) {
        if let url = URL(string: videoUrl) {
            player = AVPlayer(url: url)
            setupPlayerLayer()
            player?.play()
        }
    }
    open func getUIViewController(yourVc: UIViewController?) {
        adContainerController = yourVc
    }
    open func addGesturefromController(_ controllerView: UIViewController) {
        let playPauseGesture = UITapGestureRecognizer(target: self,
                                                      action: #selector(playPauseTapped))
        playPauseGesture.allowedPressTypes = [UIPress.PressType.playPause.rawValue as NSNumber]
        playPauseGesture.cancelsTouchesInView = true
        controllerView.view.addGestureRecognizer(playPauseGesture)
        let selectGesture = UITapGestureRecognizer(target: self,
                                                   action: #selector(playPauseTapped))
        selectGesture.allowedPressTypes = [UIPress.PressType.select.rawValue as NSNumber]
        selectGesture.cancelsTouchesInView = true
        controllerView.view.addGestureRecognizer(selectGesture)
    }
    private func setupPlayerLayer() {
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = self.view.bounds
        if let playerLayer = playerLayer {
            self.view.layer.addSublayer(playerLayer)
        }
    }
    private func fetchPlayerAssets(videoUrl: String) async {
        if let vidUrl = URL(string: videoUrl) {
            let asset = AVURLAsset(url: vidUrl)
            await fetchSubtitles(with: asset)
        }
    }
    func thumbnailImageGenerator() async {
        let asset = AVURLAsset(url: URL(
            string: "https://p-events-delivery.akamaized.net/18oijbasfvuhbfsdvoijhbsdfvljkb6/m3u8/hls_vod_mvp.m3u8")!)
        let generator = AVAssetImageGenerator(asset: asset)
        var numberofParts = 0
        if let seconds = totalDuration?.seconds {
            if seconds.isNaN {
                return
            }
            let minutes = Int(seconds / 60)
            if minutes < 10 {
                numberofParts = 15
            } else {
                numberofParts = minutes
            }
            for count in 0..<numberofParts {
                let storeTime = (CMTime(
                    seconds: Double((minutes / numberofParts) * count * 60),
                    preferredTimescale: 600)
                )
                times.append(storeTime)
            }
        }
        if #available(tvOS 16, *) {
            for await result in generator.images(for: times) {
                switch result {
                case .success(requestedTime: _, image: let image, actualTime: _):
                    storeTrickPlayImg.append(UIImage(cgImage: image))
                case .failure:
                    trickPlayImagesLoaded = false
                }
            }
            self.trickPlayImagesLoaded = true
        } else {
            let imageGenerator = AVAssetImageGenerator(asset: self.player!.currentItem!.asset)
            imageGenerator.requestedTimeToleranceBefore = .zero
            imageGenerator.requestedTimeToleranceAfter = .zero

            var timesArray: [NSValue] = []
            for time in times {
                timesArray.append(NSValue(time: time))
            }
            imageGenerator.generateCGImagesAsynchronously(forTimes: timesArray) { requestedTime, image, actualTime, result, error in
                switch result {
                case .succeeded:
                    if let image = image {
                        self.storeTrickPlayImg.append(UIImage(cgImage: image))
                    }
                case .failed:
                    self.trickPlayImagesLoaded = false
                case .cancelled:
                    print("Image generation was cancelled")
                @unknown default:
                    fatalError("Unknown result in image generation")
                }
                if self.storeTrickPlayImg.count == timesArray.count {
                    self.trickPlayImagesLoaded = true
                }
            }
        }

    }
    private func overridebackBtn() {
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(backTapped))
        gesture.allowedPressTypes = [UIPress.PressType.menu.rawValue as NSNumber]
        gesture.cancelsTouchesInView = true
        self.view.addGestureRecognizer(gesture)
    }
    @objc private func backTapped() {
        updateSubtitlePosition(relativePosition: 93)
        hidePlayerControls()
    }
    @objc private func playPauseTapped(_ gesture: UITapGestureRecognizer) {
        if checkPlayerisPlaying() == true {
            // If player is playing need to pause the content
            // pause the content, show player controls,Show trickplay image
            playerdelegate?.playerController(state: .paused, currentPlayingObject)
            pauseTheContent()
            showPlayerControls()
            playPauseImgView.isHidden = false
            if trickPlayImagesLoaded && configBuilder.showThumbnails == true {
                slider.trickPlayImg.isHidden = false
            }
        } else {
            if player?.timeControlStatus == .paused {
                playerdelegate?.playerController(state: .resumed, currentPlayingObject)

                self.slider.trickPlayImg.isHidden = true
                UIView.animate(withDuration: 0) {
                    let targetTime = Double(self.slider.value)
                    let seekTime = CMTime(value: CMTimeValue(targetTime), timescale: 1)
                    let roundedDuration = self.getTotalDurationInSeconds()
                    let remainingTime = (roundedDuration - Int(seekTime.seconds))
                    self.player?.seek(
                        to: CMTimeMakeWithSeconds(targetTime, preferredTimescale: 1),
                        toleranceBefore: CMTime.zero,
                        toleranceAfter: CMTime.zero,
                        completionHandler: { [weak self] _ in
                            self?.playerdelegate?.seekCompleted(with: (seekTime.seconds), (self!.currentPlayingObject))
                            self?.playTheContent()
                            self?.playPauseImgView.isHidden = true
                            self?.checkControlsTimerOperation()
                            if remainingTime < (self?.configBuilder.upNextInSeconds ?? 0) &&
                                self?.isUpCmingViewInitiated == false &&
                                self?.isUserTapsBackFromUpcomingView == false {
                                // While seeking if the slider is falls between after 10 seconds to 1 seconds
                                if remainingTime > 0 {
                                    // self?.removeTimerObserver()
                                    self?.desiredSecondsReached = false
                                    self?.isUpCmingViewInitiated = true
                                    self?.showUpComingContent(remainingTime)
                                }
                            }
                        })
                    self.view.layoutIfNeeded()
                }
            } else {
                checkControlsTimerOperation()
            }
        }
    }
    func checkPlayerisPlaying() -> Bool {
        if player?.timeControlStatus == .playing {
            return true
        } else {
            return false
        }
    }
    func pauseTheContent() {
        // playPauseImgView.isHidden = false
        player?.pause()
        let image = UIImage(named: "Ic_Pause", in: Bundle(for: type(of: self)), compatibleWith: nil)
        playPauseImgView.image = image
        self.playPauseTimer?.invalidate()
        self.playPauseTimer = nil
        self.playPauseTimer?.fire()
        self.playPauseTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in
            DispatchQueue.main.async { [weak self] in
                self?.playPauseImgView.isHidden = true
                self?.playPauseTimer?.invalidate()
                self?.playPauseTimer = nil
            }
        })
    }
    private func playTheContent() {
        player?.play()
    }
    private func fetchSubtitles(with assest: AVURLAsset) async {
        audioArr.removeAll()
        audioCodeArr.removeAll()
        subtitleArr.removeAll()
        subtitleCodeArr.removeAll()
        let urlAsset = AVURLAsset(url: assest.url, options: nil)
        do {
            let audioMediaSelectionGroup = try await urlAsset.loadMediaSelectionGroup(for: .audible)
            if let mediaOptions = audioMediaSelectionGroup?.options {
                for option in mediaOptions {
                    if let audioName = option.value(forKey: "title") as? String {
                        audioArr.append(audioName)
                        audioCodeArr.append(option.extendedLanguageTag ?? "en")
                    }
                }
            }
            // SUBTITLES
            let subtitleMediaSelectionGroup = try await urlAsset.loadMediaSelectionGroup(for: .legible)
            subtitleArr.append(SubtitleModel(title: "None", isEmbbeded: true))
            subtitleCodeArr.append("")
            if let mediaOptions = subtitleMediaSelectionGroup?.options {
                for option in mediaOptions {
                    if let title = option.value(forKey: "title") as? String {
                        // Confirming here it is embedded subtitle
                        subtitleArr.append(SubtitleModel(title: title, isEmbbeded: true))
                        subtitleCodeArr.append(option.extendedLanguageTag ?? "en")
                    }
                }

            }
            subtitleArr.append(SubtitleModel(title: "Hindi", isEmbbeded: false))
            subtitleCodeArr.append("")
            subtitleArr.append(SubtitleModel(title: "Malayalam", isEmbbeded: false))
            subtitleCodeArr.append("")

            if audioCodeArr.count == 0 || audioCodeArr.count == 1 {
                //            self.audioBtn.isHidden = true
                self.audioOuterview.isHidden = true
            } else {
                self.audioOuterview.isHidden = false
            }

            if self.subtitleArr.count == 0 {
                self.subtitleOuterView.isHidden = true
            } else {
                self.subtitleOuterView.isHidden = false
            }
        } catch {
            print("Error in fetching the audios")
        }
    }
    // MARK: - Player Control Actions
    private func displayPlayerControls(ishide: Bool) {
        playerControlsView.isHidden = ishide
        if ishide == true {
            updateSubtitlePosition(relativePosition: 93)
            slider.trickPlayImg.isHidden = true
        } else {
            updateSubtitlePosition(relativePosition: 65)
        }
    }
    func updateSubtitlePosition(relativePosition: CGFloat) {
        let textMarkupAttributes: [String: Any] = [
            kCMTextMarkupAttribute_OrthogonalLinePositionPercentageRelativeToWritingDirection
            as String: relativePosition
        ]
        guard let textStyle = AVTextStyleRule(textMarkupAttributes: textMarkupAttributes) else {
            return
        }
        player?.currentItem?.textStyleRules = [textStyle]
    }
    func checkControlsTimerOperation() {
        updateSubtitlePosition(relativePosition: 65)
        self.displayPlayerControls(ishide: false)
        self.gradientBGView.isHidden = false
        self.controlsDisplaytimer?.invalidate()
        self.controlsDisplaytimer = nil
        self.controlsDisplaytimer?.fire()
        self.controlsDisplaytimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: {_ in
            DispatchQueue.main.async { [weak self] in
                self?.displayPlayerControls(ishide: true)
                self?.gradientBGView.isHidden = true
                // self?.playPauseImgView.isHidden = true
                self?.updateSubtitlePosition(relativePosition: 90)
            }
        })
    }
    private func getInfoFromM3U8(videoUrl: String) {
        HLSParser.parseStreamTags(link: videoUrl, successBlock: { [weak self] successResponse in
            if successResponse > 0 {
                self?.times.removeAll()
                self?.storeTrickPlayImg.removeAll()
                // Here, we can confirm hls manifest file has trickplay images
                self?.showEmbededTrickplay = true
                if self?.configBuilder.showThumbnails == true {
                    Task {
                        await self?.thumbnailImageGenerator()
                    }
                }
            } else {
                if self?.configBuilder.showThumbnails == true && self?.showEmbededTrickplay == false {
                    self?.trickPlayParser = TrickPlayParser(
                        vttUrl: URL(string: "https://cdn.jwplayer.com/strips/wwLYM8OC-120.vtt")!, { [weak self] _ in
                            self?.trickPlayImagesLoaded = true
                            DispatchQueue.main.async {
                                // self?.slider.trickPlayImg.isHidden = false
                            }
                        })
                }
            }
        }, failedBlock: { _ in
        })
    }
    func changeFocusTo(_ view: UIView?) {
        viewToFocus = view
        setNeedsFocusUpdate()
    }
    open override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations { [unowned self] in
            if let view = context.nextFocusedView {
                if view == audioBtn {
                    self.languageImgView.image = UIImage(
                        named: "audioSelected",
                        in: Bundle(for: type(of: self)),
                        compatibleWith: nil
                    )
                } else if view == subtitleBtn {
                    self.subtitleImgView.image = UIImage(
                        named: "subtitleSelected",
                        in: Bundle(for: type(of: self)),
                        compatibleWith: nil
                    )
                } else if view == infoBtn {
                    self.infoImgView.image = UIImage(
                        named: "infoFilled",
                        in: Bundle(for: type(of: self)),
                        compatibleWith: nil
                    )
                }
            }
            if let view = context.previouslyFocusedView {
                if view == audioBtn {
                    self.languageImgView.image = UIImage(
                        named: "audioUnSelected",
                        in: Bundle(for: type(of: self)),
                        compatibleWith: nil
                    )
                } else if view == subtitleBtn {
                    self.subtitleImgView.image = UIImage(
                        named: "subtitleUnSelected",
                        in: Bundle(for: type(of: self)),
                        compatibleWith: nil
                    )
                } else if view == infoBtn {
                    self.infoImgView.image = UIImage(
                        named: "info",
                        in: Bundle(for: type(of: self)),
                        compatibleWith: nil
                    )
                }
            }
        }
    }
    @IBAction func subtitleBtn(_ sender: Any) {
        let settingView = SettingsPlayerView(
            frame: CGRect(
                x: 0, y: 0,
                width: self.view.bounds.width,
                height: self.view.bounds.height)
        )
        self.addSubview(settingView)
        self.view.bringSubviewToFront(settingView)
        pauseTheContent()
        hidePlayerControls()
        self.controlsDisplaytimer?.invalidate()
        self.controlsDisplaytimer = nil

        settingView.state = "subtitle"
        settingView.subtitlesArr = subtitleArr
        settingView.subtitlesCodeArr = subtitleCodeArr
        settingView.selectedSubtitle = self.selectedSubtitle
        settingView.playerSettingsDelegate = self
    }
    @IBAction func multipleAudioBtn(_ sender: Any) {
        let settingsView = SettingsPlayerView(frame: CGRect(
            x: 0, y: 0,
            width: self.view.bounds.width,
            height: self.view.bounds.height))
        self.addSubview(settingsView)
        self.view.bringSubviewToFront(settingsView)
        pauseTheContent()
        hidePlayerControls()
        self.controlsDisplaytimer?.invalidate()
        self.controlsDisplaytimer = nil

        settingsView.audioArr = audioArr
        settingsView.audioCodeArr = audioCodeArr
        settingsView.playerSettingsDelegate = self
        settingsView.selectedAudio = self.selectedAudio
        settingsView.state = "audio"
    }
    @IBAction func infoBtn(_ sender: Any) {
        let infoView = InfoSectionView(frame: CGRect(
            x: 0, y: 0,
            width: self.view.bounds.width,
            height: self.view.bounds.height)
        )
        self.addSubview(infoView)
        self.view.bringSubviewToFront(infoView)
        infoView.infoSectionDelegate = self
        pauseTheContent()
        hidePlayerControls()
        self.controlsDisplaytimer?.invalidate()
        self.controlsDisplaytimer = nil
    }
    func setupGestureRecognizers() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
    }
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if playerControlsView.isHidden == true {
            changeFocusTo(slider)
            if checkPlayerisPlaying() == true {
                checkControlsTimerOperation()
            } else {
                print("Player controls should be in shown ")
            }
        }
    }
    func hidePlayerControls() {
        playerControlsView.isHidden = true
        gradientBGView.isHidden = true
    }
    func showPlayerControls() {
        gradientBGView.isHidden = false
        //  self.playerControlsView.isUserInteractionEnabled = true
        self.playerControlsView.isHidden = false
    }
}
extension TringPlayerView: PlayerSettingsDelegate {
    func backbtnTapped() {
        bringPlayerViewToFront()
        showPlayerControls()
        playTheContent()
    }
    func changePlayerSetting(settingType: Int, settingName: String, index: Int, hasEmbeddedSubtile: Bool) {
        bringPlayerViewToFront()
        showPlayerControls()
        checkControlsTimerOperation()
        playTheContent()
        if settingType == 2 {
            self.selectedSubtitle = index
            subtitleLbl.isHidden = true
            self.player?.currentItem?.asset.loadMediaSelectionGroup(for: .legible) { [weak self] group, error in
                guard let group = group else {
                    print("Failed to load media selection group: \(String(describing: error))")
                    self?.isVTTSubtitleSelected = false
                    return
                }
                let locale = Locale(identifier: settingName)
                let options = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)

                if let option = options.first {
                    self?.isVTTSubtitleSelected = false
                    self?.player?.currentItem?.select(option, in: group)
                } else {
                    self?.player?.currentItem?.select(nil, in: group)
                 //   self.subtitleLbl.isHidden = true
                    // subtitle = nil
                }
            }
            if hasEmbeddedSubtile == false {
                isVTTSubtitleSelected = true
                subtitleLbl.isHidden = false
                selectedSubtileLanguage = subtitleArr[selectedSubtitle].title
            }
        }
        if settingType == 3 {
            self.selectedAudio = index
            self.player?.currentItem?.asset.loadMediaSelectionGroup(for: .audible) { group, error in
                guard let group = group else {
                    print("Failed to load media selection group: \(String(describing: error))")
                    return
                }

                let locale = Locale(identifier: settingName)
                let options = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)

                if let option = options.first {
                    // Select the desired audio option based on the locale
                    self.player?.currentItem?.select(option, in: group)
                }
            }
        }
    }
    func bringPlayerViewToFront() {
        self.addSubview(view)
        subtitleView.addSubview(subtitleLbl)
        view.addSubview(playPauseImgView)
        view.addSubview(activityIndicator)
    }
}
// MARK: - UPNEXT VIEW
extension TringPlayerView: UpNextDelegate {
    func upNextClicked(index: Int) {
        
        playerdelegate?.videoTransitionCompleted(currentPlayingObject)
        // Sometimes user clicks the upnext btn, From here we can comes to know video is completed
        playerdelegate?.videoContentCompleted(currentPlayingObject)
        bringPlayerViewToFront()
        //  playTheContent()
        showPlayerControls()
        activityIndicator.startAnimating()
        adMarkerview.removeFromSuperview()
        if configBuilder.isAdSupported == true {
            showAdsView()
        }
        self.player?.pause()
        if self.timeObserver != nil {
            self.player?.removeTimeObserver(self.timeObserver as Any)
            print("Observer is removed in refresh")
            self.timeObserver = nil
        }
        self.player = nil
        currentPlayingObject = nil
        self.player = AVPlayer(playerItem: AVPlayerItem(url: URL(string: upComingList[index].videoUrl)!))
        setupPlayerLayer()
        view.bringSubviewToFront(gradientBGView)
        view.bringSubviewToFront(contentView)
        view.bringSubviewToFront(playPauseImgView)
        view.bringSubviewToFront(activityIndicator)
        currentPlayingObject = upComingList[index]
        slider.maximumTrackTintColor = UIColor.gray
        doAsyncOperationfrom(videourl: upComingList[index].videoUrl)
        trickPlayParser = nil
        isSeeking = false
        isUserTapsBackFromUpcomingView = false
        trickPlayImagesLoaded = false
        isUpNextClickedCalled = false
        selectedSubtileLanguage = nil
        isVTTSubtitleSelected = false
        // player?.removeTimeObserver(timeObserver)
        isUpCmingViewInitiated = false
        showEmbededTrickplay = false
        playerdelegate?.videoContentStarted(currentPlayingObject)
        //  sliderConfigurations()
        // fetchPlayerAssets(videoUrl: upComingList[index].videoUrl)

        movieTitleLbl.text = upComingList[index].movieTitle
        desiredSecondsReached = true
        self.player?.play()
        upComingList.append(upComingList[index])
        upComingList.remove(at: index)
    }
    func backBtnTapped() {
        bringPlayerViewToFront()
        playTheContent()
        showPlayerControls()
        isUpCmingViewInitiated = false
        isUserTapsBackFromUpcomingView = true
        desiredSecondsReached = true
    }
    func showUpComingContent(_ remainingTime: Int = 0) {
        let comingUpview = ComingUpView(frame: CGRect(
            x: 0, y: 0,
            width: self.view.bounds.width,
            height: self.view.bounds.height)
        )
        self.addSubview(comingUpview)
        self.view.bringSubviewToFront(comingUpview)
        hidePlayerControls()
        comingUpview.movieList = upComingList
        comingUpview.upNextDelegate = self
        print("remaining Time", remainingTime)
        comingUpview.remainingTime = remainingTime
    }
}
// MARK: - ADS PART
extension TringPlayerView: AdsPlayerController {
    func allAdsCompleted() {
        if self.upComingList.count > 1 {
            print("Upcoming List", self.upComingList.count)
            self.showUpComingContent()
        }
    }
    func getAdsLoader(adsLoader: IMAAdsLoader) {
        self.adLoader = adsLoader
    }
    func showAdsView() {
        DispatchQueue.main.async {
            self.adsView.requestAds(
                adContainerViewController: self.adContainerController ?? UIViewController(),
                player: self.player!
            )
            self.adsView.adPlayerDelegate = self
        }
    }
    func getCuePoints(cueArray: [Any]) {
        for cuePoint in 0..<cueArray.count {
            print("cueArray", cueArray[cuePoint])
            var xpos = Float(cueArray[cuePoint] as? Float ?? 0.0)
            if xpos == Float(-1) {
                if let totalDuration = totalDuration {
                    let duration: CMTime = totalDuration
                    let seconds: Float64 = CMTimeGetSeconds(duration)
                    xpos = Float(seconds)
                }

            }
            let percent = (xpos/(slider.maximumValue)) * 100.0
            let position = Double(self.slider.bounds.width) * Double(percent)
            adMarkerview = UIView(frame: CGRect(x: position/100.0, y: 25, width: 6.0, height: 16))
            adMarkerview.backgroundColor = UIColor.yellow
            self.slider.addSubview(adMarkerview)
        }
    }
    func showAdsView(isHide: Bool) {
        if isHide {
            adsView.isHidden = false
            player?.pause()
        } else {
            adsView.isHidden = true
            player?.play()
        }
    }
}
extension TringPlayerView: MoreSectionDelegate {
    func hideMoreSectionView() {
        bringPlayerViewToFront()
        playTheContent()
    }
}
extension TringPlayerView: InfoSectionDelegate {
    func playFromBeginTapped() {
        player?.seek(
            to: CMTimeMakeWithSeconds(0, preferredTimescale: 1),
            toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero
        )
        bringPlayerViewToFront()
        playTheContent()
        showPlayerControls()
        checkControlsTimerOperation()
    }
    func infoSectionBackBtnTapped() {
        bringPlayerViewToFront()
        showPlayerControls()
        playTheContent()
        checkControlsTimerOperation()
    }
}
