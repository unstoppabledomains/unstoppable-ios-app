//
//  ResizableRoundedWalletImageView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.05.2022.
//

import UIKit

class ResizableRoundedWalletImageView: ResizableRoundedImageView {
    
    func setWith(walletInfo: WalletDisplayInfo, style: Style = .large) {
        image = walletInfo.source.displayIcon
        
        setSize(style.size)
        switch walletInfo.source {
        case .locallyGenerated, .external:
            setStyle(.largeImage)
        case .imported:
            setStyle(.imageCentered)
        }
    }
    
    override func additionalSetup() {
        tintColor = .foregroundDefault
    }
}

// MARK: - Style
extension ResizableRoundedWalletImageView {
    enum Style {
        case large, indicatorSmall, extraSmall, small16
        
        var size: ResizableRoundedImageView.Size {
            switch self {
            case .large: return .init(containerSize: 80, imageSize: 40)
            case .indicatorSmall: return .init(containerSize: 20, imageSize: 20)
            case .extraSmall: return .init(containerSize: 20, imageSize: 12)
            case .small16: return .init(containerSize: 16, imageSize: 16)
            }
        }
    }
}
