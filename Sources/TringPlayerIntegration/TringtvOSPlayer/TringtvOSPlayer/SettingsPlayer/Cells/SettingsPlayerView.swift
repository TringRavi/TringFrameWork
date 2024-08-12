//
//  SettingsPlayerView.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 20/06/24.
//

import UIKit

protocol PlayerSettingsDelegate: AnyObject {
    func changePlayerSetting(settingType: Int, settingName: String, index: Int, hasEmbeddedSubtile: Bool)
    func backbtnTapped()
}

class SettingsPlayerView: UIView, UITableViewDataSource, UITableViewDelegate {
    var settingsview: UIView!
    let nibName: String = "SettingsPlayerView"
    var selectedQuality = 0
    var myPreferredFocusedView: UIView?
    var subtitlesArr = [SubtitleModel]()
    var subtitlesCodeArr = [String]()
    var audioArr = [String]()
    var audioCodeArr = [String]()
    var selectedSubtitle = 0
    var selectedAudio = 0
    var state = ""
    var playerSettingsDelegate: PlayerSettingsDelegate?
    @IBOutlet weak var gradientBGView: UIView!
    @IBOutlet weak var contentTableView: UITableView!
    @IBOutlet weak var contentTitle: UILabel!
    override var preferredFocusedView: UIView? {
        return myPreferredFocusedView
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        configTableView()
        overridebackBtn()
        setInitialDetails()
        applyGradientforBG(to: gradientBGView)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("SettingsPlayerView")
    }
    fileprivate func commonInit() {
        self.settingsview = UINib(
            nibName: self.nibName,
            bundle: Bundle(for: type(of: self))).instantiate(withOwner: self, options: nil)[0] as? UIView
        self.settingsview.frame = bounds
        self.settingsview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(settingsview)
    }
    private func applyGradientforBG(to view: UIView) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        let color1 = UIColor.black.withAlphaComponent(1).cgColor
        let color2 = UIColor.black.withAlphaComponent(0.85).cgColor
        let color3 = UIColor.black.withAlphaComponent(0.5).cgColor
        gradientLayer.colors = [color1, color2, color3]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    func configTableView() {
        contentTableView.register(
            UINib(nibName: "SettingsPlayerTableViewCell",
                  bundle: Bundle(for: type(of: self))),
            forCellReuseIdentifier: "SettingsPlayerTableViewCell")
        contentTableView.delegate = self
        contentTableView.dataSource = self
    }
    func setInitialDetails() {
        if self.state == "audio" {
            if let cell = self.contentTableView.cellForRow(
                at: IndexPath(row: self.selectedAudio, section: 0))
                as? SettingsPlayerTableViewCell {
                self.myPreferredFocusedView = cell
            }
        } else if self.state == "subtitle" {
            if let cell = self.contentTableView.cellForRow(
                at: IndexPath(row: self.selectedSubtitle, section: 0)
            ) as? SettingsPlayerTableViewCell {
                self.myPreferredFocusedView = cell
            }
        }
        self.setNeedsFocusUpdate()
    }
    func overridebackBtn() {
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(backTapped))
        gesture.allowedPressTypes = [UIPress.PressType.menu.rawValue as NSNumber]
        gesture.cancelsTouchesInView = true
        self.settingsview.addGestureRecognizer(gesture)
    }
    @objc private func backTapped() {
        playerSettingsDelegate?.backbtnTapped()
        settingsview.removeFromSuperview()
    }
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let view = context.nextFocusedView {
            self.myPreferredFocusedView = view
            if let nextFoc = context.nextFocusedView as? SettingsPlayerTableViewCell {
                nextFoc.backgroundColor = UIColor(hexString: ConfigBuilder().appThemeColor, alpha: 1.0)
                nextFoc.focusStyle = .custom
            }
            if context.previouslyFocusedView != nil {
                if let prevFocus = context.previouslyFocusedView as? SettingsPlayerTableViewCell {
                    prevFocus.focusStyle = .custom
                    prevFocus.backgroundColor = UIColor.clear
                }
            }
        }
    }
    // MARK: - TABLEVIEW DELEGATES
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.state == "subtitle" {
            self.contentTitle.text = "Subtitles"
            return self.subtitlesArr.count
        } else if self.state == "audio" {
            self.contentTitle.text = "Audios"
            return self.audioArr.count
        }
        return 0
    }
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: "SettingsPlayerTableViewCell",
            for: indexPath
        ) as? SettingsPlayerTableViewCell {
            if self.state == "subtitle" {
                if self.selectedSubtitle == indexPath.row {
                    cell.tickImg.isHidden = false
                } else {
                    cell.tickImg.isHidden = true
                }
                cell.selectingLbl.text = subtitlesArr[indexPath.row].title
            } else if self.state == "audio" {
                cell.selectingLbl.text = self.audioArr[indexPath.row]
                if self.selectedAudio == indexPath.row {
                    cell.tickImg.isHidden = false
                } else {
                    cell.tickImg.isHidden = true
                }
            }
            return cell
        }
        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.state == "subtitle" {
            selectedSubtitle = indexPath.row
            playerSettingsDelegate?.changePlayerSetting(
             settingType: 2,
             settingName: subtitlesCodeArr[selectedSubtitle],
             index: selectedSubtitle,
             hasEmbeddedSubtile: subtitlesArr[selectedSubtitle].isEmbbeded)
        } else if self.state == "audio" {
            selectedAudio = indexPath.row
            playerSettingsDelegate?.changePlayerSetting(
                settingType: 3,
                settingName: audioCodeArr[selectedAudio],
                index: selectedAudio,
                hasEmbeddedSubtile: false
            )
        }
        settingsview.removeFromSuperview()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
