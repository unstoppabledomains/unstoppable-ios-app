//
//  ViewPullUpConfigurationType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.01.2024.
//

import Foundation

enum ViewPullUpConfigurationType {
    case `default`(ViewPullUpDefaultConfiguration)
    case custom(ViewPullUpCustomContentConfiguration)
    
    @MainActor
    func calculateHeight() -> CGFloat {
        switch self {
        case .default(let conf):
            return conf.calculateHeight()
        case .custom(let conf):
            return conf.height
        }
    }
}
