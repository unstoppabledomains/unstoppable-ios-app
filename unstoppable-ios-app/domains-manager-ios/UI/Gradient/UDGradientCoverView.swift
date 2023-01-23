//
//  UDGradientCoverView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2022.
//

import UIKit

final class UDGradientCoverView: GradientView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        baseInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        baseInit()
    }
    
}

// MARK: - Private methods
private extension UDGradientCoverView {
    func baseInit() {
        gradientColors = [.backgroundDefault.withAlphaComponent(0.01), .backgroundDefault]
    }
}
