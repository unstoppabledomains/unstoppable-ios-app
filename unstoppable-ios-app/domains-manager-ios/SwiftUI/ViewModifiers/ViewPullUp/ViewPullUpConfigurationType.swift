//
//  ViewPullUpConfigurationType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.01.2024.
//

import Foundation

enum ViewPullUpConfigurationType {
    case `default`(ViewPullUpDefaultConfiguration)
    
    @MainActor
    func calculateHeight() -> CGFloat {
        switch self {
        case .default(let conf):
            return conf.calculateHeight()
        }
    }
}
