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
    case viewModifier(ViewPullUpViewModifierConfiguration)
    
    var analyticName: Analytics.PullUp {
        switch self {
        case .default(let conf):
            return conf.analyticName
        case .custom(let conf):
            return conf.analyticName
        case .viewModifier(let conf):
            return conf.analyticName
        }
    }
    
    @MainActor
    func calculateHeight() -> CGFloat {
        switch self {
        case .default(let conf):
            return conf.calculateHeight()
        case .custom(let conf):
            return conf.height
        case .viewModifier(let conf):
            return conf.height
        }
    }
    
   
    
}

// MARK: - Equatable
extension ViewPullUpConfigurationType: Equatable {
    static func == (lhs: ViewPullUpConfigurationType, rhs: ViewPullUpConfigurationType) -> Bool {
        lhs.analyticName == rhs.analyticName
    }
}
