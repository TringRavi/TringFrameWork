//
//  MoreSectionDetailView.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 17/07/24.
//

import UIKit

protocol MoreSectionDelegate: AnyObject {
    func hideMoreSectionView()
}

class MoreSectionDetailView: UIView, UITextViewDelegate {
   // override var canBecomeFocused: Bool { true }
    @IBOutlet weak var returnToVideoBtn: UIButton!
    @IBOutlet weak var contentTitle: UILabel!
    @IBOutlet weak var contentDescView: UITextView!
    var moreSectionView: UIView!
    let nibName: String = "MoreSectionDetailView"
    var moreSectionDelegate: MoreSectionDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        makeFirstcellToBeFocused()
        setUITextView()
        overridebackBtn()
    }
    deinit{
        print("ComingUpView DeInitialized")
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    private func overridebackBtn() {
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(backTapped))
        gesture.allowedPressTypes = [UIPress.PressType.menu.rawValue as NSNumber]
        gesture.cancelsTouchesInView = true
        self.moreSectionView.addGestureRecognizer(gesture)
    }
    @objc private func backTapped() {
        moreSectionDelegate?.hideMoreSectionView()
        moreSectionView.removeFromSuperview()
    }
    private func setUITextView() {
        contentDescView.isSelectable = true
        contentDescView.isUserInteractionEnabled = true
        contentDescView.isScrollEnabled = true
        contentDescView.showsVerticalScrollIndicator = true
        contentDescView.flashScrollIndicators()
        contentDescView.automaticallyAdjustsScrollIndicatorInsets = true
        contentDescView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        contentDescView.delegate = self
    }
    fileprivate func commonInit() {
        self.moreSectionView = UINib(
            nibName: self.nibName,
            bundle: Bundle(for: type(of: self))).instantiate(
                withOwner: self,
                options: nil
            )[0] as? UIView
        self.moreSectionView.frame = bounds
        self.moreSectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(moreSectionView)
    }
    private func makeFirstcellToBeFocused() {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.3) { [weak self] in
            self?.returnToVideoBtn.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            self?.returnToVideoBtn.layer.borderWidth = 3.0
            self?.returnToVideoBtn.layer.borderColor = UIColor.white.cgColor
            self?.returnToVideoBtn.layer.cornerRadius = 8.0
            self?.returnToVideoBtn.setNeedsFocusUpdate()
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        contentDescView.flashScrollIndicators()
    }
    @IBAction func returnBtnTapped(_ sender: Any) {
        moreSectionDelegate?.hideMoreSectionView()
        moreSectionView.removeFromSuperview()
    }
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ [unowned self] in
            if let view = context.nextFocusedView {
                if view == contentDescView {
                    view.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
                }
            }
            if let view = context.previouslyFocusedView {
                if view == contentDescView {
                    view.transform = .identity
                }
            }
        })
    }
}
