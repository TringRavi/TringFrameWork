//
//  Utilities.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 12/06/24.
//

import Foundation
import AVKit

extension AVPlayer {
    func addProgressObserver(action: @escaping ((Double) -> Void)) -> Any {
        // Seconds -> How frequent my interval should be Invoked, So based on this my slider will be updated
        let interval = CMTime(seconds: 1,
                                  preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        return self.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            if let duration = self?.currentItem?.duration {
                let _ = CMTimeGetSeconds(duration), time = CMTimeGetSeconds(time)
               // _ = (time/duration)
                action(Double(time))
            }
        })
    }
}
extension UIImageView {
    func setImageFromStringrURL(stringUrl: String, completion: @escaping(_ Image: Data) -> Void) {
        if let url = URL(string: stringUrl) {
            URLSession.shared.dataTask(with: url) { (data, _, _) in
                // Error handling..
                guard let imageData = data else {
                    return
                }
                completion(imageData)
            }.resume()
        }
    }
}
extension UIView {
    func applyGradient(to view: UIView) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        let color1 = UIColor.init(hexString: "#141523").withAlphaComponent(1).cgColor
        let color2 = UIColor.init(hexString: "#141523").withAlphaComponent(1).cgColor
        let color3 = UIColor.init(hexString: "#141523").withAlphaComponent(0.3).cgColor
        gradientLayer.colors = [color1, color2, color3]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
}
extension Array {
    subscript(indexChecked index: Int) -> Element? {
        return(index < count) ? self[index] : nil
    }
}
extension UIColor {
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if hexString.hasPrefix("#") {
            scanner.currentIndex = hexString.index(after: hexString.startIndex)
        }
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        let mask = 0x000000FF
        let redValue = Int(color >> 16) & mask
        let greenValue = Int(color >> 8) & mask
        let blueValue = Int(color) & mask
        let red   = CGFloat(redValue) / 255.0
        let green = CGFloat(greenValue) / 255.0
        let blue  = CGFloat(blueValue) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
