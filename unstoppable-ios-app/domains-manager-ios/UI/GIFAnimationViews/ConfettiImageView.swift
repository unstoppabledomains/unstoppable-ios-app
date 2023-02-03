//
//  ConfettiImageView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2022.
//

import UIKit

final class ConfettiImageView: GIFAnimationImageView {
 
    private var gradientView: GradientView!
    override var gifAnimation: GIFAnimationsService.GIF { .happyEnd }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
   
    static func prepareAnimationsAsync() {
        #if DEBUG
        if TestsEnvironment.isTestModeOn {
            return
        }
        #endif
        Task {
            await GIFAnimationsService.shared.prepareGIF(.happyEnd)
        }
    }
    
    static func releaseAnimations() {
        GIFAnimationsService.shared.removeGIF(.happyEnd)
    }
    
    func setGradientHidden(_ isHidden: Bool) {
        gradientView.isHidden = isHidden
    }
}

// MARK: - Setup methods
private extension ConfettiImageView {
    func setup() {
        setGradientView()
    }
    
    func setGradientView() {
        gradientView = GradientView()
        gradientView.embedInSuperView(self)
        gradientView.gradientDirection = .topToBottom
        gradientView.gradientColors = [.backgroundDefault.withAlphaComponent(0.01), .backgroundDefault]
    }
}
