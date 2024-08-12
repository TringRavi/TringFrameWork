//
//  HLSParser.swift
//  TringtvOSPlayer
//
//  Created by Ravi Chandran on 15/07/24.
//

import Foundation
struct HLSParser {
    static func parseStreamTags(
        link: String,
        successBlock: @escaping (Int) -> Void,
        failedBlock: @escaping (_ error: Error?) -> Void
    ) {
        var request = URLRequest(url: URL(string: link)!)
        request.httpMethod = "Get"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                failedBlock(error) // return data & close
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("response = \(String(describing: response))")
            }
            let responseString = String(decoding: data, as: UTF8.self)
            let tmpStr = "EXT-X-I-FRAME-STREAM-INF:"
            let arrayCrop = responseString.components(separatedBy: tmpStr)
            let cropArray = arrayCrop.dropFirst()
            successBlock(cropArray.count)
        }
        task.resume()
    }
}
