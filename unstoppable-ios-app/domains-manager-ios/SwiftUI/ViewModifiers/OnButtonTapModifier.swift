//
//  OnButtonTapModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.01.2024.
//

import SwiftUI

struct OnButtonTapModifier: ViewModifier {
    let shouldVibrate: Bool
    let callback: EmptyCallback?
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(TapGesture().onEnded {
                if shouldVibrate {
                    UDVibration.buttonTap.vibrate()
                }
                callback?()
            })
    }
}

extension View {
    func onButtonTap(shouldVibrate: Bool = true,
                     callback: EmptyCallback? = nil) -> some View {
        modifier(OnButtonTapModifier(shouldVibrate: shouldVibrate, callback: callback))
    }
}
