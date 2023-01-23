//
//  ViewWithDashesProgress.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol ViewWithDashesProgress {
    var dashesProgressView: DashesProgressView! { get }
    func setDashesProgress(_ progress: Double?)
    func setDistanceToDashesView(_ distance: CGFloat)
}

extension ViewWithDashesProgress {
    func setDashesProgress(_ progress: Double?) {
        if let progress = progress {
            dashesProgressView.setProgress(progress)
            dashesProgressView.alpha = 1
        } else {
            dashesProgressView.alpha = 0
        }
    }
    
    func setDistanceToDashesView(_ distance: CGFloat = 0) {
        if let constraint = dashesProgressView
            .superview?
            .constraints
            .filter({ constraint -> Bool in
                if constraint.firstItem === dashesProgressView && constraint.firstAttribute == .bottom {
                    return true
                } else if constraint.secondItem === dashesProgressView && constraint.secondAttribute == .bottom {
                    return true
                }
                
                return false
            }).first {
            constraint.constant = distance
        }
    }
}
