//
//  Color.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.08.2023.
//

import SwiftUI

extension Color {
    // Foreground
    static let foregroundDefault = Color(uiColor: .foregroundDefault)
    static let foregroundSecondary = Color(uiColor: .foregroundSecondary)
    static let foregroundMuted = Color(uiColor: .foregroundMuted)
    static let foregroundSubtle = Color(uiColor: .foregroundSubtle)
    static let foregroundOnEmphasis = Color(uiColor: .foregroundOnEmphasis)
    static let foregroundOnEmphasisOpacity = Color(uiColor: .foregroundOnEmphasisOpacity)
    static let foregroundOnEmphasisOpacity2 = Color(uiColor: .foregroundOnEmphasisOpacity2)
    static let foregroundOnEmphasis2 = Color(uiColor: .foregroundOnEmphasis2)
    static let foregroundOnEmphasis2Opacity = Color(uiColor: .foregroundOnEmphasis2Opacity)
    static let foregroundAccent = Color(uiColor: .foregroundAccent)
    static let foregroundAccentSubtle = Color(uiColor: .foregroundAccentSubtle)
    static let foregroundAccentMuted = Color(uiColor: .foregroundAccentMuted)
    static let foregroundSuccess = Color(uiColor: .foregroundSuccess)
    static let foregroundSuccessMuted = Color(uiColor: .foregroundSuccessMuted)
    static let foregroundDanger = Color(uiColor: .foregroundDanger)
    static let foregroundDangerMuted = Color(uiColor: .foregroundDangerMuted)
    static let foregroundDangerSubtle = Color(uiColor: .foregroundDangerSubtle)
    static let foregroundWarning = Color(uiColor: .foregroundWarning)
    static let foregroundWarningMuted = Color(uiColor: .foregroundWarningMuted)
    
    // Background
    static let backgroundDefault = Color(uiColor: .backgroundDefault)
    static let backgroundMuted = Color(uiColor: .backgroundMuted)
    static let backgroundMuted2 = Color(uiColor: .backgroundMuted2)
    static let backgroundSubtle = Color(uiColor: .backgroundSubtle)
    static let backgroundOverlay = Color(uiColor: .backgroundOverlay)
    static let backgroundOverlayOpacity = Color(uiColor: .backgroundOverlayOpacity)
    static let backgroundOverlayOpacity2 = Color(uiColor: .backgroundOverlayOpacity2)
    static let backgroundEmphasis = Color(uiColor: .backgroundEmphasis)
    static let backgroundEmphasisOpacity = Color(uiColor: .backgroundEmphasisOpacity)
    static let backgroundEmphasisOpacity2 = Color(uiColor: .backgroundEmphasisOpacity2)
    static let backgroundAccent = Color(uiColor: .backgroundAccent)
    static let backgroundAccentEmphasis = Color(uiColor: .backgroundAccentEmphasis)
    static let backgroundAccentEmphasis2 = Color(uiColor: .backgroundAccentEmphasis2)
    static let backgroundSuccess = Color(uiColor: .backgroundSuccess)
    static let backgroundSuccessEmphasis = Color(uiColor: .backgroundSuccessEmphasis)
    static let backgroundWarning = Color(uiColor: .backgroundWarning)
    static let backgroundWarningEmphasis = Color(uiColor: .backgroundWarningEmphasis)
    static let backgroundDanger = Color(uiColor: .backgroundDanger)
    static let backgroundDangerEmphasis = Color(uiColor: .backgroundDangerEmphasis)
    static let backgroundDangerEmphasis2 = Color(uiColor: .backgroundDangerEmphasis2)
    
    // Border
    static let borderDefault = Color(uiColor: .borderDefault)
    static let borderMuted = Color(uiColor: .borderMuted)
    static let borderSubtle = Color(uiColor: .borderSubtle)
    static let borderEmphasis = Color(uiColor: .borderEmphasis)
    
    // Brand
    static let brandUnstoppableBlue = Color(uiColor: .brandUnstoppableBlue)
    static let brandSkyBlue = Color(uiColor: .brandSkyBlue)
    static let brandOrange = Color(uiColor: .brandOrange)
    static let brandBlack = Color(uiColor: .brandBlack)
    static let brandWhite = Color(uiColor: .brandWhite)
    static let brandUnstoppablePink = Color(uiColor: .brandUnstoppablePink)
    static let brandDeepPurple = Color(uiColor: .brandDeepPurple)
    static let brandElectricGreen = Color(uiColor: .brandElectricGreen)
    static let brandElectricYellow = Color(uiColor: .brandElectricYellow)
    static let brandDeepBlue = Color(uiColor: .brandDeepBlue)
    
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
