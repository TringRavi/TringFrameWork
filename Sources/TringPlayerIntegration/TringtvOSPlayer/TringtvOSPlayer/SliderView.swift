//
//  SliderView.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 12/06/24.
//

import Foundation
import UIKit
import CoreMedia
import AVFoundation

extension TringPlayerView {
    public func sliderConfigurations(
        maximumTintColorCode: String = "#FFFFFF",
        minimumTintColorCode: String = "#FFFFFF"
    ) {
        slider.addTarget(self, action: #selector(didSliderValueChanges(slider:event:)), for: .valueChanged)
        slider.isFocusedCheck = true
        if let totalDuration = totalDuration {
            let seconds: Float64 = CMTimeGetSeconds(totalDuration)
            slider.totalDuration = seconds
            slider.minimumValue = 0
            slider.maximumValue = Float(seconds)
            slider.minimumTrackTintColor = UIColor(hexString: configBuilder.appThemeColor, alpha: 1.0)
            slider.maximumTrackTintColor = UIColor.gray
            timeobserverSetup()
        }
    }
    func timeobserverSetup(_ time: Double = 0.0) {
        let roundedSeconds = getTotalDurationInSeconds()
        self.timeObserver = player?.addProgressObserver { [weak self] progress in
            let remainingTime = (roundedSeconds - Int(progress))
            if let currentPlayingObject = self?.currentPlayingObject {
                self?.playerdelegate?.playerController(state: .playing, currentPlayingObject)
                self?.playerdelegate?.playerHeartbeatRate(at: progress, currentPlayingObject)
            }

            self?.addBufferObservation()
            self?.seekStartingPosition = progress
            if remainingTime == (self?.configBuilder.upNextInSeconds) &&
                self?.desiredSecondsReached == true &&
                !(self?.isUpCmingViewInitiated ?? false) {
                if self?.configBuilder.upNextInSeconds ?? 0 > 0 {
                    self?.playerdelegate?.videoTransitionScreenStarted(self!.currentPlayingObject)
                    self?.isUpCmingViewInitiated = true
                    self?.showUpComingContent(self?.configBuilder.upNextInSeconds ?? 0)
                    self?.desiredSecondsReached = false
                }
            }
            self?.totalDurationLbl.text = "-" + (self?.formatSecondsToString(TimeInterval(remainingTime)) ?? "")
            if !(self?.isSeeking ?? false) {
                self?.slider.value = Float((progress))
            }
            self?.slider.currentDurationLbl.text = self?.formatSecondsToString(progress)
            if self?.isVTTSubtitleSelected == true {
//                if let subtitle = self?.subtitle {
//                    self?.extractInfoFromParser(from: subtitle, at: progress)
//                }
                guard let selectedLanguage = self?.selectedSubtileLanguage else {
                        return
                }
                if let Subtitle = self?.getSubtitle(for: selectedLanguage) {
                    self?.extractInfoFromParser(from: Subtitle, at: progress)
                }

            }
            if self?.configBuilder.showThumbnails == true {
                if let trickPlayParser = self?.trickPlayParser {
                    self?.extractInfoFromTrickPlayParser(
                        from: trickPlayParser,
                        at: TimeInterval(self?.slider.value ?? 0.0)
                    )
                }
            }
            if self?.showEmbededTrickplay == true && self?.configBuilder.showThumbnails == true {
                let targetTime = Double(self?.slider.value ?? 0.0)
                let seekTime = CMTime(
                    value: CMTimeValue(targetTime),
                    timescale: 1
                )
                let currentMin = Int(seekTime.seconds / 60)
                if currentMin != self?.previousMinute {
                    self?.previousMinute = currentMin
                    self?.slider.trickPlayImg.image = self?.storeTrickPlayImg[indexChecked: currentMin]
                }
            }
        }
    }
    func getSubtitle(for language: String) -> VTTParser? {
        return subtitles[language]
    }
    func removeTimerObserver() {
        if self.timeObserver != nil {
            if self.player?.rate == 1.0 { // it is required as you have to check if player is playing
                self.player?.removeTimeObserver(self.timeObserver as Any)
                self.timeObserver = nil
            }
        }
    }
    func getTotalDurationInSeconds() -> Int {
        if let totalDuration = totalDuration {
            let seconds: Float64 = CMTimeGetSeconds(totalDuration)
            return Int(seconds)
        }
        return 0
    }
    func didStartSwipe() {
        playerdelegate?.seekStarted(from: seekStartingPosition, currentPlayingObject!)
        isSeeking = true
        removeTimerObserver()
        pauseTheContent()
        controlsDisplaytimer?.invalidate()
        controlsDisplaytimer = nil
        showPlayerControls()
    }
    func didFinishSwipe() {
        isSeeking = false
        timeobserverSetup()
    }
    func hideTotalDurationLbl(_ isHide: Bool) {
        if isHide {
            totalDurationLbl.isHidden = true
        } else {
            totalDurationLbl.isHidden = false
        }
    }
    @objc func didSliderValueChanges(slider: TvOSSlider, event: UIEvent) {
        let targetTime = Double(slider.value)
        let seekTime = CMTime(value: CMTimeValue(targetTime), timescale: 1)
        let roundedDuration = getTotalDurationInSeconds()
        let remainingTime = (roundedDuration - Int(seekTime.seconds))
        self.slider.currentDurationLbl.text = self.formatSecondsToString(seekTime.seconds)
        self.totalDurationLbl.text = "-" + self.formatSecondsToString(TimeInterval(remainingTime))
        if configBuilder.showThumbnails == true && trickPlayImagesLoaded {
            slider.trickPlayImg.isHidden = false
            if let trickPlayParser = self.trickPlayParser {
                self.extractInfoFromTrickPlayParser(from: trickPlayParser, at: TimeInterval(slider.value))
            }
        }
        if self.showEmbededTrickplay == true && self.configBuilder.showThumbnails == true && trickPlayImagesLoaded {
            slider.trickPlayImg.isHidden = false
            let targetTime = Double(slider.value)
            let seekTime = CMTime(value: CMTimeValue(targetTime), timescale: 1)
            let currentMin = Int(seekTime.seconds / 60)
            if currentMin != previousMinute && seekCount > 5 {
                previousMinute = currentMin
                seekCount = 0
                self.slider.trickPlayImg.image = storeTrickPlayImg[indexChecked: currentMin]
            }
            seekCount += 1
        }
        slider.value = Float(targetTime)
    }
    fileprivate func extractInfoFromParser(from parser: VTTParser, at time: TimeInterval) {
        if let group = parser.search(time: time) {
            subtitleLbl.isHidden = false
            subtitleLbl.text = group.text
        } else {
            subtitleLbl.isHidden = true
        }
    }
    fileprivate func extractInfoFromTrickPlayParser(from parser: TrickPlayParser, at time: TimeInterval) {
        if let group = parser.search(time: time) {
            extractCoordinates(from: group.text)
        }
    }
    // Function to extract coordinates
    fileprivate func extractCoordinates(from string: String) {
        // Split the string to isolate the coordinate part
        let parts = string.split(separator: "#")
        guard parts.count == 2 else { return }
        let coordinatesPart = parts[1]
        // Check if the coordinates part starts with "xywh="
        guard coordinatesPart.hasPrefix("xywh=") else { return }
        // Extract the numbers part
        let numbersPart = coordinatesPart.dropFirst(5) // Remove "xywh="
        // Split the numbers part by comma
        let coordinates = numbersPart.split(separator: ",")
        guard coordinates.count == 4 else { return }
        // Convert the coordinate values to integers
        if let xCordinate = Int(coordinates[0]),
           let yCordinate = Int(coordinates[1]),
           let width = Int(coordinates[2]),
           let height = Int(coordinates[3]) {
            setImage(xCoordinate: xCordinate, yCoordinate: yCordinate, width: width, height: height)
        }
    }
    private func setImage(xCoordinate: Int, yCoordinate: Int, width: Int, height: Int) {
        if let thumbnailImage = slider.thumbnailImage {
            UIGraphicsBeginImageContext(CGSize(width: width, height: height))
            let xCrop = CGFloat(xCoordinate)
            let yCrop = CGFloat(yCoordinate)
            let widthCrop = CGFloat(width)
            let heightCrop = CGFloat(height)
            if let croppedImage = thumbnailImage.cgImage?.cropping(to: CGRect.init(
                x: xCrop,
                y: yCrop,
                width: widthCrop,
                height: heightCrop)) {
                let newImage  = UIImage.init(cgImage: croppedImage)
                slider.trickPlayImg.image = newImage
            }
            UIGraphicsEndImageContext()
        }
    }
    func dowloadTrickPlayImg(trickplayUrl: String) {
        if self.slider.thumbnailImage == nil {
            slider.trickPlayImg.setImageFromStringrURL(stringUrl: trickplayUrl, completion: {image in
                DispatchQueue.main.async {
                    self.slider.thumbnailImage = UIImage(data: image)
                }
            })
        }
    }
    func formatSecondsToString(_ secounds: TimeInterval) -> String {
        if secounds.isNaN { return "-- : --" }
        let hours: Int = Int(secounds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes: Int = Int(secounds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds: Int = Int(secounds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}
