//
//  TASubtitles.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 24/06/24.
//

import Foundation

public class TrickPlayParser {
    public var groups: [Group] = []
    public struct Group: CustomStringConvertible {
        var index: Int
        var start: TimeInterval
        var end: TimeInterval
        var text: String
        init(_ index: Int, _ start: NSString, _ end: NSString, _ text: NSString) {
            self.index = index
            self.start = Group.parseDuration(start as String)
            self.end   = Group.parseDuration(end as String)
            self.text  = text as String
        }
        init(index: Int, start: String, end: String, text: String) {
            self.index = index
            self.start = Group.parseDuration(start)
            self.end   = Group.parseDuration(end)
            self.text  = text
        }
        // converting the string to timeinterval format.
        static func parseDuration(_ fromStr: String) -> TimeInterval {
            let scanner = Scanner(string: fromStr)
            var hour: Double = 0
            if fromStr.split(separator: ":").count > 2 {
                hour = scanner.scanDouble() ?? 0.0
                _ = scanner.scanString(":")
            }

            let min = scanner.scanDouble() ?? 0.0
            _ = scanner.scanString(":")
            let sec = scanner.scanDouble() ?? 0.0
            if scanner.scanString(",") == nil {
                _ = scanner.scanString(".")
            }
            let millisecond = scanner.scanDouble() ?? 0.0
            return (hour * 3600.0) + (min * 60.0) + sec + (millisecond / 1000.0)
        }
        public var description: String {
            return "Subtile Group ==========\nindex : \(index),\nstart : \(start)\nend   :\(end)\ntext  :\(text)"
        }
    }
    public init(url: URL? = nil, encoding: String.Encoding? = nil) {
        DispatchQueue.global(qos: .background).async {
            do {
                let string: String
                if let encoding = encoding {
                    string = try String(contentsOf: url!, encoding: encoding)
                } else {
                    string = try String(contentsOf: url!)
                }
                self.groups = TrickPlayParser.parseSubRip(string, { _ in
                    print("All the images are appended in array")
                }) ?? []
            } catch {
                print("| [Error] failed to load the subtitle")
            }
        }
    }
    public init(vttUrl: URL, encoding: String.Encoding? = nil, _ handler: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                if let encoding = encoding {
                    let subTitle = try String(contentsOf: vttUrl, encoding: encoding)
                    if subTitle.contains("WEBVTT") {
                        let convert = subTitle.replacingOccurrences(of: "WEBVTT", with: "")
                        let scr = self.convertvttToSrt(convert)
                        self.groups = TrickPlayParser.parseSubRip(scr, { _ in
                            handler(true)
                        }) ?? []
                    } else {
                        self.groups = TrickPlayParser.parseSubRip(subTitle, { _ in
                            handler(true)
                        }) ?? []
                    }
                } else {
                    let subTitle = try String(contentsOf: vttUrl)
                    if subTitle.contains("WEBVTT") {
                        let convert = subTitle.replacingOccurrences(of: "WEBVTT", with: "")
                        let scr = self.convertvttToSrt(convert)
                        self.groups = TrickPlayParser.parseSubRip(scr, { _ in
                            handler(true)
                        }) ?? []
                    } else {
                        self.groups = TrickPlayParser.parseSubRip(subTitle, { _ in
                            handler(true)
                        }) ?? []
                    }
                }
            } catch {
                print("| [Error] failed to load \(vttUrl.absoluteString) \(error.localizedDescription)")
            }
        }
    }
    func convertvttToSrt(_ payLoad: String) -> String {
        var datas = payLoad.components(separatedBy: "\n\n")
        var scrText = String()
        for index in 0..<datas.count where !datas[index].isEmpty {
            let add = String(index) + "\n" + datas[index] + "\r\n\r\n"
            datas[index] = add
            scrText.append(add)
        }
        return scrText
    }
    public func search(time: TimeInterval) -> Group? {
        let result = groups.first(where: { group -> Bool in
            if group.start <= time && group.end >= time {
                return true
            }
            return false
        })
        return result
    }
    /**
     Search for target group for time
     
     - parameter time: target time
     
     - returns: result group or nil
     */
    /**
     Parse str string into Group Array
     
     - parameter payload: target string
     
     - returns: result group
     */
    fileprivate static func parseSubRip(_ payload: String, _ completion: (Bool) -> Void) -> [Group]? {
        var groups: [Group] = []
        let scanner = Scanner(string: payload)
        var index = 0
        while !scanner.isAtEnd {
            var line: NSString?
            // taking the single line
            if let scannedString = scanner.scanUpToCharacters(from: .newlines) {
                line = scannedString as NSString
            } else {
                continue
                // Handle case where no characters up to newline are found
            }
            guard let timeline = line else {continue}
            if !timeline.contains(" --> ") {
                continue
            }
            // segregatting the time as two components using -->
            let times = String(timeline).components(separatedBy: " --> ")
            if times.count != 2 {continue}
            if let scannedString = scanner.scanUpToString("\r\n\r\n") {
                var text = scannedString.replacingOccurrences(of: "\r\n", with: " ")
                text = text.trimmingCharacters(in: .whitespaces)
                index += 1
                let group = Group(index: index, start: times[0], end: times[1], text: text)
                groups.append(group)
            }
        }
        completion(true)
        return groups
    }
}
