//
//  Font.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 21.08.2023.
//

import SwiftUI

extension Font {
    static func currentFont(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        interFont(ofSize: size, weight: weight)
    }
    
    static func interFont(ofSize fontSize: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        let fontName = UIFont.interFontNameFor(weight: weight)
        return .custom(fontName, size: fontSize)
    }
        
    static func helveticaNeueCustom(size: CGFloat) -> Font {
        .custom("HelveticaNeue-Custom", size: size)
    }
}

