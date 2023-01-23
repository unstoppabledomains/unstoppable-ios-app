//
//  GIFAnimationImageView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2022.
//

import UIKit

class GIFAnimationImageView: UIImageView {
    
    private var isGIFAnimationOn = false
    var gifAnimation:  GIFAnimationsService.GIF { .happyEnd }

}

// MARK: - Open methods
extension GIFAnimationImageView {
    func startConfettiAnimationAsync() {
        isGIFAnimationOn = true
        setAnimationAsync()
    }
    
    func stopConfettiAnimation() {
        isGIFAnimationOn = false
        self.image = nil
    }
}

// MARK: - Private methods
private extension GIFAnimationImageView {
    func setAnimationAsync() {
        Task {
            let image = await GIFAnimationsService.shared.getGIF(gifAnimation)
            self.image = image
        }
    }
}
