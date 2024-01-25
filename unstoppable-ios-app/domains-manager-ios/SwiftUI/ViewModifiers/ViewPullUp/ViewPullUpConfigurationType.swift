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
    
    var analyticName: Analytics.PullUp {
        switch self {
        case .default(let conf):
            return conf.analyticName
        case .custom(let conf):
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
        }
    }
    
    var additionalAnalyticParameters: Analytics.EventParameters {
        switch self {
        case .default(let conf):
            return conf.additionalAnalyticParameters
        case .custom(let conf):
            return conf.additionalAnalyticParameters
        }
    }
    var dismissCallback: EmptyCallback? {
        switch self {
        case .default(let conf):
            return conf.dismissCallback
        case .custom(let conf):
            return conf.dismissCallback
        }
    }

}

// MARK: - Equatable
extension ViewPullUpConfigurationType: Equatable, Identifiable {
    var id: String { analyticName.rawValue }
    
    static func == (lhs: ViewPullUpConfigurationType, rhs: ViewPullUpConfigurationType) -> Bool {
        lhs.analyticName == rhs.analyticName
    }
}
