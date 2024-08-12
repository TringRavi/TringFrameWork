//
//  ComingUpView.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 28/06/24.
//

import UIKit

protocol UpNextDelegate: AnyObject {
    func upNextClicked(index: Int)
    func backBtnTapped()
}

class ComingUpView: UIView {
    @IBOutlet weak var comingUpCollection: UICollectionView!
    @IBOutlet weak var upNextLbl: UILabel!
    @IBOutlet weak var upComingContentImg: UIImageView!
    @IBOutlet weak var upComingContentTitle: UILabel!
    @IBOutlet weak var upComingContentDuration: UILabel!
    @IBOutlet weak var upNextBtn: UIButton!
    @IBOutlet weak var contentView: UIView!
    var upNextview: UIView!
    let nibName: String = "ComingUpView"
    var movieList = [PlayerItem]()
    var upNextDelegate: UpNextDelegate?
    var countDownTimer: Timer?
    var countDownCount = ConfigBuilder().upNextInSeconds
    var remainingTime = 0
    var myPreferredFocusedView: UIView?
    override var preferredFocusedView: UIView? {
        return myPreferredFocusedView
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        overridebackBtn()
        contentView.applyGradient(to: contentView)
        print("ComingUpView Initialized")
        setContentDetails()
    }
    deinit{
        print("ComingUpView DeInitialized")
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    func setContentDetails() {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.3) { [weak self] in
            let imgUrl = self?.movieList[0].thumbnailImg ?? ""
            self?.upComingContentImg.setImageFromStringrURL(stringUrl: imgUrl, completion: { imgData in
                DispatchQueue.main.async {
                    self?.upComingContentImg.image = UIImage(data: imgData)
                }
            })
            self?.startTimerForCountDown()
            self?.upComingContentDuration.text = "S1:E4" + "  •  " + "56 mins"
            self?.upComingContentTitle.text = self?.movieList[0].movieTitle
            self?.upNextBtn.setNeedsFocusUpdate()
        }
    }
    func setupUI() {
        upNextBtn.backgroundColor = UIColor(hexString: ConfigBuilder().appThemeColor, alpha: 1.0)
        upNextBtn.layer.cornerRadius = 6.0
        upComingContentImg.layer.cornerRadius = 26.0
    }
    fileprivate func commonInit() {
        self.upNextview = UINib(
            nibName: self.nibName,
            bundle: Bundle(for: type(of: self))).instantiate(
                withOwner: self, options: nil
            )[0] as? UIView
        self.upNextview.frame = bounds
        self.upNextview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(upNextview)
    }
    func overridebackBtn() {
            let gesture = UITapGestureRecognizer(target: self,
                                                 action: #selector(backTapped))
            gesture.allowedPressTypes = [UIPress.PressType.menu.rawValue as NSNumber]
            gesture.cancelsTouchesInView = true
            self.upNextview.addGestureRecognizer(gesture)
        }
        @objc private func backTapped() {
            countDownTimer?.invalidate()
            countDownTimer = nil
            upNextDelegate?.backBtnTapped()
            upNextview.removeFromSuperview()
         }
    func configUpComingCollectionView() {
        let nib = UINib(
            nibName: "ComingUpCell",
            bundle: Bundle(for: type(of: self))
        )
        comingUpCollection.register(nib, forCellWithReuseIdentifier: "comingupcell")
        comingUpCollection.delegate = self
        comingUpCollection.dataSource = self
    }
    @IBAction func upNextBtnTapped(_ sender: Any) {
        upNextDelegate?.upNextClicked(index: 0)
        countDownTimer?.invalidate()
        countDownTimer = nil
        upNextview.removeFromSuperview()
    }
    func startTimerForCountDown() {
        if remainingTime == 0 {
            self.upNextview.removeFromSuperview()
            upNextDelegate?.upNextClicked(index: 0)
           // countDownCount = ConfigBuilder().upNextInSeconds
    // If the remening time is exactly zero, Up next clicked(index =0), Automatically taken caren by player end item
        } else {
            countDownCount = remainingTime
            self.countDownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                DispatchQueue.main.async { [weak self] in
                    self?.countDownCount = (self?.countDownCount ?? 0) - 1
                        self?.upNextLbl.text = "Playing in \(self!.countDownCount) Sec"
                        if self?.countDownCount == 0 {
                        self?.countDownTimer?.invalidate()
                        self?.countDownTimer = nil
                       // self?.upNextDelegate?.upNextClicked(index: 0)
                        self?.upNextview.removeFromSuperview()
                    }
                }
            })
            self.upNextLbl.text = "Playing in \(self.countDownCount) Sec"
            self.setupUI()
        }
    }
}
extension ComingUpView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movieList.count
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if let cell = comingUpCollection.dequeueReusableCell(
            withReuseIdentifier: "comingupcell",
            for: indexPath) as? ComingUpCell {
            cell.movieTitleLbl.text = movieList[indexPath.row].movieTitle
            cell.upComingMovieImg.layer.cornerRadius = 8.0
            cell.upComingMovieImg.setImageFromStringrURL(
                stringUrl: movieList[indexPath.row].thumbnailImg,
                completion: { imgData in
                DispatchQueue.main.async {
                    cell.upComingMovieImg.image = UIImage(data: imgData)
                }
            })
            return cell
        }
        return UICollectionViewCell()
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        upNextDelegate?.upNextClicked(index: indexPath.row)
        countDownTimer?.invalidate()
        countDownTimer = nil
        upNextview.removeFromSuperview()
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 380, height: 300)
    }
}
