//
//  InfoSectionView.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 27/07/24.
//

import UIKit
protocol InfoSectionDelegate: AnyObject {
    func playFromBeginTapped()
    func infoSectionBackBtnTapped()
}

class InfoSectionView: UIView {
    var infoView: UIView!
    let nibName: String = "InfoSectionView"
    var infoSectionDelegate: InfoSectionDelegate?
    @IBOutlet weak var currentTitle: UILabel!
    @IBOutlet weak var currentContentImg: UIImageView!
    @IBOutlet weak var currentContentDesc: UILabel!
    @IBOutlet weak var currentContentDuration: UILabel!
    @IBOutlet weak var playFromBegining: UIButton!
    @IBOutlet weak var contentView: UIView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        setupUI()
        overridebackBtn()
        setInitialDetails()
        contentView.applyGradient(to: contentView)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    func setInitialDetails() {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.3) { [weak self] in
            let imgUrl = "https://cdn.jwplayer.com/v2/media/azjHGeTe/poster.jpg?width=1920"
            self?.currentContentImg.setImageFromStringrURL(stringUrl: imgUrl, completion: { imgData in
                DispatchQueue.main.async {
                    self?.currentContentImg.image = UIImage(data: imgData)
                }
            })
            self?.currentContentDuration.text = "S1:E4" + "  •  " + "56 mins"
            // self?.currentTitle.text = self?.movieList[0].movieTitle
            self?.playFromBegining.setNeedsFocusUpdate()
        }
    }
    func setupUI() {
        playFromBegining.backgroundColor = UIColor(hexString: ConfigBuilder().appThemeColor, alpha: 1.0)
        playFromBegining.layer.cornerRadius = 6.0
        currentContentImg.layer.cornerRadius = 26.0
    }
    fileprivate func commonInit() {
        self.infoView = UINib(
            nibName: self.nibName,
            bundle: Bundle(for: type(of: self))).instantiate(
                withOwner: self,
                options: nil
            )[0] as? UIView
        self.infoView.frame = bounds
        self.infoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(infoView)
    }
    func overridebackBtn() {
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(backTapped))
        gesture.allowedPressTypes = [UIPress.PressType.menu.rawValue as NSNumber]
        gesture.cancelsTouchesInView = true
        self.infoView.addGestureRecognizer(gesture)
    }
    @objc private func backTapped() {
        infoSectionDelegate?.infoSectionBackBtnTapped()
        infoView.removeFromSuperview()
    }
    @IBAction func fromBeginningTapped(_ sender: Any) {
        infoSectionDelegate?.playFromBeginTapped()
        infoView.removeFromSuperview()
    }
}
