//
//  WebsiteURLValidator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.10.2022.
//

import Foundation

protocol WebsiteURLValidator {
    func isWebsiteValid(_ website: String) -> Bool
}

extension WebsiteURLValidator {
    func isWebsiteValid(_ website: String) -> Bool {
        guard !website.isEmpty,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return false }
        
        let stringSize = website.utf16.count
        if let match = detector.firstMatch(in: website,
                                           options: [],
                                           range: NSRange(location: 0,
                                                          length: stringSize)) {
            // it is a link, if the match covers the whole string
            return match.range.length == stringSize
        } else {
            return false
        }
    }
}
