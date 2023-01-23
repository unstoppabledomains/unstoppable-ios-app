//
//  CAAnimation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2022.
//

import UIKit

extension CABasicAnimation {
    static func infiniteRotateAnimation(duration: TimeInterval) -> CABasicAnimation {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = -Double.pi * 2
        rotationAnimation.duration = duration
        rotationAnimation.repeatCount = .infinity
        
        return rotationAnimation
    }
}
