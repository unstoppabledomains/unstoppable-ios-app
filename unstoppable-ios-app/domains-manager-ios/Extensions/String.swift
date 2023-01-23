//
//  String.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.04.2022.
//

import Foundation
import UIKit

extension Character {
    static let dotSeparator: Character = "."
}

extension String {
    static let dotSeparator: String = "."

    func ranges(of searchString: String) -> [NSRange] {
        let _indices = indices(of: searchString)
        let count = searchString.count
        return _indices.map({ index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0+count) }).map({ NSRange($0, in: self)})
    }
    
    func indices(of occurrence: String) -> [Int] {
        var indices = [Int]()
        var position = startIndex
        while let range = range(of: occurrence, range: position..<endIndex) {
            let i = distance(from: startIndex,
                             to: range.lowerBound)
            indices.append(i)
            let offset = occurrence.distance(from: occurrence.startIndex,
                                             to: occurrence.endIndex) - 1
            guard let after = index(range.lowerBound,
                                    offsetBy: offset,
                                    limitedBy: endIndex) else {
                break
            }
            position = index(after: after)
        }
        return indices
    }
    
    var walletAddressTruncated: String {
        guard self.count > 10 else { return self }
        
        let leftPart = self[startIndex...self.index(startIndex, offsetBy: 5)]
        let rightPart = self[index(endIndex, offsetBy: -4)...self.index(self.endIndex, offsetBy: -1)]
        
        return leftPart + "..." + rightPart
    }
    
    var capitalizedFirstCharacter: String {
        guard let firstCharacter = self.first else { return "" }
        
        var arr = Array(self)
        arr[0] = Character("\(firstCharacter)".capitalized)

        return String(arr)
    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont, lineHeight: CGFloat? = 0) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        var attributes: [NSAttributedString.Key : Any] = [.font: font]
        if let lineHeight = lineHeight {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = lineHeight
            paragraphStyle.maximumLineHeight = lineHeight
            attributes[.paragraphStyle] = paragraphStyle
        }
        let boundingBox = self.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: attributes,
                                            context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}

extension String {
    var canBeIPFSPath: Bool {
        guard count >= 46 else { return false }
        
        return prefix(2) == "Qm" || prefix(3) == "baf"
    }
    
    var ipfsURL: URL? {
        URL(string: "https://ipfs.io/ipfs/" + self)
    }
}
