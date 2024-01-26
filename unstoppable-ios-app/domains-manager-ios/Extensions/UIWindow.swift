//
//  UIWindow.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.01.2024.
//

import UIKit

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
