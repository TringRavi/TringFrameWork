//
//  TvOSSlider.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 12/06/24.
//

import UIKit
import GameController

private let trackViewHeight: CGFloat = 10
private let thumbSize: CGFloat = 30
private let animationDuration: TimeInterval = 0.3
private let defaultValue: Float = 0
private let defaultMinimumValue: Float = 0
private let defaultMaximumValue: Float = 1
private let defaultIsContinuous: Bool = true
private let defaultThumbTintColor: UIColor = .white
private let defaultTrackColor: UIColor = .gray
private let defaultMininumTrackTintColor: UIColor = .blue
private let defaultFocusScaleFactor: CGFloat = 1.00
private let defaultStepValue: Float = 0.1
private let decelerationRate: Float = 0.92
private let decelerationMaxVelocity: Float = 1000
private let fineTunningVelocityThreshold: Float = 600

/// A control used to select a single value from a continuous range of values.
protocol SliderDelegate: AnyObject {
    func didStartSwipe()
    func didFinishSwipe()
    func hideTotalDurationLbl(_ isHide: Bool)
}
// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
public final class TvOSSlider: UIControl {
    // MARK: - Public
    weak var sliderDelegate: SliderDelegate?

    /// The slider’s current value.
    @IBInspectable
    public var value: Float {
        get {
            return storedValue
        }
        set {
            storedValue = min(maximumValue, newValue)
            storedValue = max(minimumValue, storedValue)
            let boundsWidth = self.trackView.bounds.width
            let range = self.maximumValue - self.minimumValue
            let normalizedValue = (self.storedValue - self.minimumValue) / range
            var offset = boundsWidth * CGFloat(normalizedValue)
            offset = min(self.trackView.bounds.width, offset)
            self.thumbViewCenterXConstraint.constant = offset
            self.currentDurationXConstraint.constant = offset
            if offset < 90 {
                sliderDelegate?.hideTotalDurationLbl(false)
                self.trickImgCenterXConstraint.constant = offset + 120
            } else if offset > 1650 {
                sliderDelegate?.hideTotalDurationLbl(true)
                self.trickImgCenterXConstraint.constant = offset - 120
            } else {
                sliderDelegate?.hideTotalDurationLbl(false)
                self.trickImgCenterXConstraint.constant = offset
            }
        }
    }
    /// The minimum value of the slider.
    @IBInspectable
    public var minimumValue: Float = defaultMinimumValue {
        didSet {
            value = max(value, minimumValue)
        }
    }
    /// The maximum value of the slider.
    @IBInspectable
    public var maximumValue: Float = defaultMaximumValue {
        didSet {
            value = min(value, maximumValue)
        }
    }
    /// A Boolean value indicating whether changes in the slider’s value generate continuous update events.
    @IBInspectable
    public var isContinuous: Bool = defaultIsContinuous
    @IBInspectable
    public var minimumTrackTintColor: UIColor? = defaultMininumTrackTintColor {
        didSet {
            minimumTrackView.backgroundColor = minimumTrackTintColor
        }
    }
    public var isFocusedCheck: Bool = false
    // The color used to tint the default maximum track images.
    @IBInspectable
    public var maximumTrackTintColor: UIColor? {
        didSet {
            maximumTrackView.backgroundColor = maximumTrackTintColor
        }
    }
    /// The color used to tint the default thumb images.
    @IBInspectable
    public var thumbTintColor: UIColor = defaultThumbTintColor {
        didSet {
            thumbView.backgroundColor = thumbTintColor
        }
    }
    /// Scale factor applied to the slider when receiving the focus
    @IBInspectable
    public var focusScaleFactor: CGFloat = defaultFocusScaleFactor {
        didSet {
            updateStateDependantViews()
        }
    }
    /// Value added or subtracted from the current value on steps left or right updates
    public var stepValue: Float = defaultStepValue
    public var totalDuration: Float64 = 0.0
    /**
     Sets the slider’s current value, allowing you to animate the change visually.

     - Parameters:
     - value: The new value to assign to the value property
     - animated: Specify true to animate the change in value; otherwise,
     specify false to update the slider’s appearance immediately.
     Animations are performed asynchronously and do not block the calling thread.
     */
    public func setValue(_ value: Float, animated: Bool) {
        self.value = value
        stopDeceleratingTimer()
        if animated {
            UIView.animate(withDuration: animationDuration) {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }
    /**
     Assigns a minimum track image to the specified control states.

     - Parameters:
     - image: The minimum track image to associate with the specified states.
     - state: The control state with which to associate the image.
     */
    public func setMinimumTrackImage(_ image: UIImage?, for state: UIControl.State) {
        minimumTrackViewImages[state.rawValue] = image
        updateStateDependantViews()
    }
    /**
     Assigns a maximum track image to the specified control states.

     - Parameters:
     - image: The maximum track image to associate with the specified states.
     - state: The control state with which to associate the image.
     */
    public func setMaximumTrackImage(_ image: UIImage?, for state: UIControl.State) {
        maximumTrackViewImages[state.rawValue] = image
        updateStateDependantViews()
    }

    public func setThumbImage(_ image: UIImage?, for state: UIControl.State) {
        thumbViewImages[state.rawValue] = image
        updateStateDependantViews()
    }
    /// The minimum track image currently being used to render the slider.
    public var currentMinimumTrackImage: UIImage? {
        return minimumTrackView.image
    }
    /// Contains the maximum track image currently being used to render the slider.
    public var currentMaximumTrackImage: UIImage? {
        return maximumTrackView.image
    }
    /// The thumb image currently being used to render the slider.
    public var currentThumbImage: UIImage? {
        return thumbView.image
    }
    public func minimumTrackImage(for state: UIControl.State) -> UIImage? {
        return minimumTrackViewImages[state.rawValue]
    }
    public func maximumTrackImage(for state: UIControl.State) -> UIImage? {
        return maximumTrackViewImages[state.rawValue]
    }
    public func thumbImage(for state: UIControl.State) -> UIImage? {
        return thumbViewImages[state.rawValue]
    }
    // MARK: - Initializers
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    // MARK: - UIControlStates
    public override var isEnabled: Bool {
        didSet {
            panGestureRecognizer.isEnabled = isEnabled
            updateStateDependantViews()
        }
    }
    public override var isSelected: Bool {
        didSet {
            updateStateDependantViews()
        }
    }
    public override var isHighlighted: Bool {
        didSet {
            updateStateDependantViews()
        }
    }

    // MARK: - Private
    private typealias ControlState = UInt
    public var storedValue: Float = defaultValue
    private var thumbViewImages: [ControlState: UIImage] = [:]
    private var thumbView: UIImageView!
    var trickPlayImg: UIImageView!
    var thumbnailImage: UIImage?
    var currentDurationLbl = UILabel()
    var seekLineImgView: UIImageView!
    private var trackViewImages: [ControlState: UIImage] = [:]
    var trackView: UIImageView!
    private var minimumTrackViewImages: [ControlState: UIImage] = [:]
    private var minimumTrackView: UIImageView!
    private var maximumTrackViewImages: [ControlState: UIImage] = [:]
    private var maximumTrackView: UIImageView!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var leftTapGestureRecognizer: UITapGestureRecognizer!
    private var rightTapGestureRecognizer: UITapGestureRecognizer!
    private var thumbViewCenterXConstraint: NSLayoutConstraint!
    private var trickImgCenterXConstraint: NSLayoutConstraint!
    private var thumbTextCenterXConstraint: NSLayoutConstraint!
    private var currentDurationXConstraint: NSLayoutConstraint!
    private var seekLineImageViewXConstraint: NSLayoutConstraint!
    private var dPadState: DPadState = .select
    private weak var deceleratingTimer: Timer?
    private var deceleratingVelocity: Float = 0
    private var thumbViewCenterXConstraintConstant: Float = 0
    private func setUpView() {
        setUpTrackView()
        setUpMinimumTrackView()
        setUpMaximumTrackView()
        setUpThumbView()
        setUpTrickPlayImg()
        setUpCurrentTimingLbl()
        setUpTrackViewConstraints()
        setUpMinimumTrackViewConstraints()
        setUpMaximumTrackViewConstraints()
        setUpThumbViewConstraints()
        setUpTrickPlayConstraints()
        setUpCurrentTimeLblConstraints()
        seekLineImgViewSetUp()
        setUpGestures()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerConnected(note:)),
            name: .GCControllerDidConnect,
            object: nil
        )
        updateStateDependantViews()
    }
    private func setUpThumbView() {
        thumbView = UIImageView()
        thumbView.layer.cornerRadius = thumbSize/2
        thumbView.backgroundColor = thumbTintColor
        addSubview(thumbView)
    }
    private func setUpTrickPlayImg() {
        trickPlayImg = UIImageView()
        trickPlayImg.layer.borderColor = UIColor(hexString: ConfigBuilder().appThemeColor).cgColor
        trickPlayImg.layer.borderWidth = 3
        addSubview(trickPlayImg)
        trickPlayImg.isHidden = true
    }
    private func setUpCurrentTimingLbl() {
        currentDurationLbl.textAlignment = .center
        currentDurationLbl.textColor = UIColor.white
        currentDurationLbl.text = "00:00"
        currentDurationLbl.font = UIFont.systemFont(ofSize: 20)
        addSubview(currentDurationLbl)
    }
    private func setUpTrackView() {
        trackView = UIImageView()
        trackView.layer.cornerRadius = trackViewHeight/2
        trackView.backgroundColor = .blue
        addSubview(trackView)
    }
    private func setUpMinimumTrackView() {
        minimumTrackView = UIImageView()
        minimumTrackView.layer.cornerRadius = trackViewHeight/2
        minimumTrackView.backgroundColor = .gray
        addSubview(minimumTrackView)
    }
    private func setUpMaximumTrackView() {
        maximumTrackView = UIImageView()
        maximumTrackView.layer.cornerRadius = trackViewHeight/2
        maximumTrackView.backgroundColor = .blue
        addSubview(maximumTrackView)
    }
    private func setUpTrackViewConstraints() {
        trackView.translatesAutoresizingMaskIntoConstraints = false
        trackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        trackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        trackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        trackView.heightAnchor.constraint(equalToConstant: trackViewHeight).isActive = true
    }
    private func setUpMinimumTrackViewConstraints() {
        minimumTrackView.translatesAutoresizingMaskIntoConstraints = false
        minimumTrackView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor).isActive = true
        minimumTrackView.trailingAnchor.constraint(equalTo: thumbView.centerXAnchor).isActive = true
        minimumTrackView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor).isActive = true
        minimumTrackView.heightAnchor.constraint(equalToConstant: trackViewHeight).isActive = true
    }
    private func setUpMaximumTrackViewConstraints() {
        maximumTrackView.translatesAutoresizingMaskIntoConstraints = false
        maximumTrackView.leadingAnchor.constraint(equalTo: thumbView.centerXAnchor).isActive = true
        maximumTrackView.trailingAnchor.constraint(equalTo: trackView.trailingAnchor).isActive = true
        maximumTrackView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor).isActive = true
        maximumTrackView.heightAnchor.constraint(equalToConstant: trackViewHeight).isActive = true
    }
    private func setUpThumbViewConstraints() {
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        thumbView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        thumbView.widthAnchor.constraint(equalToConstant: thumbSize).isActive = true
        thumbView.heightAnchor.constraint(equalToConstant: thumbSize).isActive = true
        thumbViewCenterXConstraint = thumbView.centerXAnchor.constraint(
            equalTo: trackView.leadingAnchor,
            constant: CGFloat(value)
        )
        thumbViewCenterXConstraint.isActive = true
    }
    private func setUpTrickPlayConstraints() {
        trickPlayImg.translatesAutoresizingMaskIntoConstraints = false
        trickPlayImg.widthAnchor.constraint(equalToConstant: 278).isActive = true
        trickPlayImg.heightAnchor.constraint(equalToConstant: 156).isActive = true
        trickImgCenterXConstraint = trickPlayImg.centerXAnchor.constraint(
            equalTo: trackView.leadingAnchor,
            constant: CGFloat(value)
        )
        trickPlayImg.centerXAnchor.constraint(equalTo: thumbView.centerXAnchor).isActive = true
        trickImgCenterXConstraint.isActive = true
    }
    private func setUpCurrentTimeLblConstraints() {
        currentDurationLbl.translatesAutoresizingMaskIntoConstraints = false
        currentDurationXConstraint = thumbView.centerXAnchor.constraint(
            equalTo: trackView.leadingAnchor,
            constant: CGFloat(value)
        )
        currentDurationLbl.topAnchor.constraint(
            equalTo: thumbView.bottomAnchor,
            constant: 20
        ).isActive = true
        currentDurationLbl.centerXAnchor.constraint(equalTo: thumbView.centerXAnchor).isActive = true
        currentDurationXConstraint.isActive = true
    }
    private func seekLineImgViewSetUp() {
        seekLineImgView = UIImageView()
        addSubview(seekLineImgView)
        seekLineImgView.image = UIImage(named: "SeekLine", in: Bundle(for: type(of: self)), compatibleWith: nil)
        seekLineImgView.translatesAutoresizingMaskIntoConstraints = false
        seekLineImageViewXConstraint = thumbView.centerXAnchor.constraint(
            equalTo: trackView.leadingAnchor,
            constant: CGFloat(value)
        )
        seekLineImgView.topAnchor.constraint(equalTo: thumbView.bottomAnchor, constant: 5).isActive = true
        seekLineImgView.centerXAnchor.constraint(equalTo: thumbView.centerXAnchor).isActive = true
        trickPlayImg.bottomAnchor.constraint(equalTo: trackView.topAnchor, constant: -40).isActive = true
        trickImgCenterXConstraint.isActive = true
    }
    private func setUpGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(panGestureWasTriggered(panGestureRecognizer:))
        )
        addGestureRecognizer(panGestureRecognizer)
        leftTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(leftTapWasTriggered))
        leftTapGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.leftArrow.rawValue)]
        leftTapGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        addGestureRecognizer(leftTapGestureRecognizer)
        rightTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(rightTapWasTriggered))
        rightTapGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.rightArrow.rawValue)]
        rightTapGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        addGestureRecognizer(rightTapGestureRecognizer)
    }
    private func updateStateDependantViews() {
        let minStateImage = minimumTrackViewImages[state.rawValue]
        let minNormalImage = minimumTrackViewImages[UIControl.State.normal.rawValue]
        let maxStateImage = maximumTrackViewImages[state.rawValue]
        let maxNormalImage = maximumTrackViewImages[UIControl.State.normal.rawValue]
        let minTrackImage = minStateImage ?? minNormalImage
        let maxTrackImage =  maxStateImage ?? maxNormalImage

        minimumTrackView.image = minTrackImage
        maximumTrackView.image = maxTrackImage
        thumbView.image = thumbViewImages[state.rawValue] ?? thumbViewImages[UIControl.State.normal.rawValue]
        if isFocused {
            transform = CGAffineTransform(scaleX: focusScaleFactor, y: focusScaleFactor)
        } else {
            transform = CGAffineTransform.identity
        }
    }

    @objc private func handleDeceleratingTimer(timer: Timer) {
        let centerX = thumbViewCenterXConstraintConstant + deceleratingVelocity * 0.01
        let percent = centerX / Float(trackView.frame.width)
        value = minimumValue + ((maximumValue - minimumValue) * percent)
        if isContinuous {
            sendActions(for: .valueChanged)
        }
        thumbViewCenterXConstraintConstant = Float(thumbViewCenterXConstraint.constant)
        deceleratingVelocity *= decelerationRate
        if !isFocused || abs(deceleratingVelocity) < 1 {
            stopDeceleratingTimer()
        }
    }
    private func stopDeceleratingTimer() {
        deceleratingTimer?.invalidate()
        deceleratingTimer = nil
        deceleratingVelocity = 0
        sendActions(for: .valueChanged)
    }
    // MARK: - Actions
    @objc
    private func panGestureWasTriggered(panGestureRecognizer: UIPanGestureRecognizer) {
        if self.isVerticalGesture(panGestureRecognizer) {
            return
        }
        if isFocusedCheck == false {
            return
        }
        let translation = Float(panGestureRecognizer.translation(in: self).x)
        let velocity = Float(panGestureRecognizer.velocity(in: self).x)
        switch panGestureRecognizer.state {
        case .began:
            stopDeceleratingTimer()
            sliderDelegate?.didStartSwipe()
            thumbViewCenterXConstraintConstant = Float(thumbViewCenterXConstraint.constant)
        case .changed:
            let centerX = thumbViewCenterXConstraintConstant + translation / 5
            let percent = centerX / Float(trackView.frame.width)
            value = minimumValue + ((maximumValue - minimumValue) * percent)
            if isContinuous {
                sendActions(for: .valueChanged)
            }
        case .ended, .cancelled:
            sliderDelegate?.didFinishSwipe()
            thumbViewCenterXConstraintConstant = Float(thumbViewCenterXConstraint.constant)
            if abs(velocity) > fineTunningVelocityThreshold {
                let direction: Float = velocity > 0 ? 1 : -1
                deceleratingVelocity = abs(velocity) > decelerationMaxVelocity ?
                decelerationMaxVelocity * direction :
                velocity
                deceleratingTimer = Timer.scheduledTimer(
                    timeInterval: 0.01,
                    target: self, selector: #selector(handleDeceleratingTimer(timer:)),
                    userInfo: nil,
                    repeats: false
                )
            } else {
                stopDeceleratingTimer()
            }
        default:
            break
        }
    }
    @objc
    private func leftTapWasTriggered() {
        if isFocusedCheck {
            setValue(value-stepValue, animated: true)
        }
    }
    @objc
    private func rightTapWasTriggered() {
        if isFocusedCheck {
            setValue(value+stepValue, animated: true)
        }
    }
    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            switch press.type {
            case .select where dPadState == .left:
                panGestureRecognizer.isEnabled = false
                leftTapWasTriggered()
            case .select where dPadState == .right:
                panGestureRecognizer.isEnabled = false
                rightTapWasTriggered()
            case .select:
                panGestureRecognizer.isEnabled = false
            default:
                break
            }
        }
        panGestureRecognizer.isEnabled = true
        super.pressesBegan(presses, with: event)
    }
    public override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        coordinator.addCoordinatedAnimations({
            self.updateStateDependantViews()
        }, completion: nil)
    }

    private func isVerticalGesture(_ recognizer: UIPanGestureRecognizer) -> Bool {
        let translation = recognizer.translation(in: self)
        if abs(translation.y) > abs(translation.x) {
            return true
        }
        return false
    }
    @objc private func controllerConnected(note: NSNotification) {
        guard let controller = note.object as? GCController else { return }
        guard let micro = controller.microGamepad else { return }
        let threshold: Float = 0.7
        micro.reportsAbsoluteDpadValues = true
        micro.dpad.valueChangedHandler = { [weak self] (_, xPos, _) in
            if xPos < -threshold {
                self?.dPadState = .left
            } else if xPos > threshold {
                self?.dPadState = .right
            } else {
                self?.dPadState = .select
            }
        }
    }
}
