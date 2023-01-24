//
//  UIColor.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.04.2022.
//

import UIKit
 
extension UIColor {
    // Foreground
    static let foregroundDefault = UIColor(named: "foregroundDefault") ?? .black
    static let foregroundSecondary = UIColor(named: "foregroundSecondary") ?? .black
    static let foregroundMuted = UIColor(named: "foregroundMuted") ?? .black
    static let foregroundSubtle = UIColor(named: "foregroundSubtle") ?? .black
    static let foregroundOnEmphasis = UIColor(named: "foregroundOnEmphasis") ?? .black
    static let foregroundOnEmphasis2 = UIColor(named: "foregroundOnEmphasis2") ?? .black
    static let foregroundOnEmphasisOpacity = UIColor(named: "foregroundOnEmphasisOpacity") ?? .black
    static let foregroundOnEmphasisOpacity2 = UIColor(named: "foregroundOnEmphasisOpacity2") ?? .black
    static let foregroundAccent = UIColor(named: "foregroundAccent") ?? .black
    static let foregroundAccentSubtle = UIColor(named: "foregroundAccentSubtle") ?? .black
    static let foregroundAccentMuted = UIColor(named: "foregroundAccentMuted") ?? .black
    static let foregroundSuccess = UIColor(named: "foregroundSuccess") ?? .black
    static let foregroundSuccessMuted = UIColor(named: "foregroundSuccessMuted") ?? .black
    static let foregroundDanger = UIColor(named: "foregroundDanger") ?? .black
    static let foregroundDangerMuted = UIColor(named: "foregroundDangerMuted") ?? .black
    static let foregroundDangerSubtle = UIColor(named: "foregroundDangerSubtle") ?? .black
    static let foregroundWarning = UIColor(named: "foregroundWarning") ?? .black
    static let foregroundWarningMuted = UIColor(named: "foregroundWarningMuted") ?? .black
    
    // Background
    static let backgroundDefault = UIColor(named: "backgroundDefault") ?? .black
    static let backgroundMuted = UIColor(named: "backgroundMuted") ?? .black
    static let backgroundMuted2 = UIColor(named: "backgroundMuted2") ?? .black
    static let backgroundSubtle = UIColor(named: "backgroundSubtle") ?? .black
    static let backgroundOverlay = UIColor(named: "backgroundOverlay") ?? .black
    static let backgroundOverlayOpacity = UIColor(named: "backgroundOverlayOpacity") ?? .black
    static let backgroundOverlayOpacity2 = UIColor(named: "backgroundOverlayOpacity2") ?? .black
    static let backgroundEmphasis = UIColor(named: "backgroundEmphasis") ?? .black
    static let backgroundEmphasisOpacity = UIColor(named: "backgroundEmphasisOpacity") ?? .black
    static let backgroundEmphasisOpacity2 = UIColor(named: "backgroundEmphasisOpacity2") ?? .black
    static let backgroundAccent = UIColor(named: "backgroundAccent") ?? .black
    static let backgroundAccentEmphasis = UIColor(named: "backgroundAccentEmphasis") ?? .black
    static let backgroundAccentEmphasis2 = UIColor(named: "backgroundAccentEmphasis2") ?? .black
    static let backgroundSuccess = UIColor(named: "backgroundSuccess") ?? .black
    static let backgroundSuccessEmphasis = UIColor(named: "backgroundSuccessEmphasis") ?? .black
    static let backgroundWarning = UIColor(named: "backgroundWarning") ?? .black
    static let backgroundWarningEmphasis = UIColor(named: "backgroundWarningEmphasis") ?? .black
    static let backgroundDanger = UIColor(named: "backgroundDanger") ?? .black
    static let backgroundDangerEmphasis = UIColor(named: "backgroundDangerEmphasis") ?? .black
    static let backgroundDangerEmphasis2 = UIColor(named: "backgroundDangerEmphasis2") ?? .black

    // Border
    static let borderDefault = UIColor(named: "borderDefault") ?? .black
    static let borderMuted = UIColor(named: "borderMuted") ?? .black
    static let borderSubtle = UIColor(named: "borderSubtle") ?? .black
    static let borderEmphasis = UIColor(named: "borderEmphasis") ?? .black
    
    // Brand
    static let brandUnstoppableBlue = UIColor(named: "brandUnstoppableBlue") ?? .black
    static let brandSkyBlue = UIColor(named: "brandSkyBlue") ?? .black
    static let brandOrange = UIColor(named: "brandOrange") ?? .black
    static let brandBlack = UIColor(named: "brandBlack") ?? .black
    static let brandWhite = UIColor(named: "brandWhite") ?? .black
    static let brandUnstoppablePink = UIColor(named: "brandUnstoppablePink") ?? .black
    static let brandDeepPurple = UIColor(named: "brandDeepPurple") ?? .black
    static let brandElectricGreen = UIColor(named: "brandElectricGreen") ?? .black
    static let brandElectricYellow = UIColor(named: "brandElectricYellow") ?? .black
}

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 300, height: 300)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
