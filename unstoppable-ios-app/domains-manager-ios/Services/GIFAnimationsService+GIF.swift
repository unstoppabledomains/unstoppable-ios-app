//
//  GIFAnimationsService+GIF.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

extension GIFAnimationsService {
    enum GIF: Int {
        case happyEnd
        
        var name: String {
            switch self {
            case .happyEnd: return "allDoneConfettiAnimation"
            }
        }
        
        var maskingType: GIFMaskingType? {
            switch self {
            case .happyEnd: return .maskWhite
            }
        }
    }
}
enum GIFMaskingType {
    case maskWhite
    
    var maskingColorComponents: [CGFloat] {
        switch self {
        case .maskWhite:
            return [222, 255, 222, 255, 222, 255]
        }
    }
    }
