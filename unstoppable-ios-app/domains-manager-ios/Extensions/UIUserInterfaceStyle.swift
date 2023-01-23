//
//  UIUserInterfaceStyle.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import UIKit

extension UIUserInterfaceStyle {
    var visibleName: String {
        switch self {
        case .unspecified:
            return String.Constants.settingsAppearanceThemeSystem.localized()
        case .light:
            return String.Constants.settingsAppearanceThemeLight.localized()
        case .dark:
            return String.Constants.settingsAppearanceThemeDark.localized()
        @unknown default:
            return String.Constants.settingsAppearanceThemeSystem.localized()
        }
    }
    
    var analyticsName: String {
        switch self {
        case .unspecified:
            return "system"
        case .light:
            return "light"
        case .dark:
            return "dark"
        @unknown default:
            return "unknown"
        }
    }
}
