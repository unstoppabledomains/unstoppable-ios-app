//
//  LoadingIndicatorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.07.2022.
//

import UIKit

final class LoadingIndicatorView: BlinkingView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
}

// MARK: - Setup methods
private extension LoadingIndicatorView {
    func setup() {
        backgroundColor = .backgroundSubtle
    }
}
