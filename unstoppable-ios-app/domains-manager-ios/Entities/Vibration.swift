//
//  Vibration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.04.2022.
//

import UIKit

enum Vibration {
    case error
    case success
    case warning
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
    
    public func vibrate() {
        Task { @MainActor in
            switch self {
            case .error:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .warning:
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .light:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .medium:
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case .heavy:
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case .soft:
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            case .rigid:
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            case .selection:
                UISelectionFeedbackGenerator().selectionChanged()
            }
        }
    }
}

enum UDVibration {
    case buttonTap
    
    public func vibrate() {
        switch self {
        case .buttonTap:
            Vibration.light.vibrate()
        }
    }
}
