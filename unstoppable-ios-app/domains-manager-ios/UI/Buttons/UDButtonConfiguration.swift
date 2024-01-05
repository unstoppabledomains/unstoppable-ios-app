//
//  UDButtonConfiguration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.12.2022.
//

import UIKit

struct UDButtonConfiguration {
    var backgroundIdleColor: UIColor = .backgroundAccentEmphasis
    var backgroundHighlightedColor: UIColor = .backgroundAccentEmphasis
    var backgroundDisabledColor: UIColor = .backgroundAccentEmphasis
    var textColor: UIColor = .foregroundOnEmphasis
    var textHighlightedColor: UIColor = .foregroundOnEmphasis
    var textDisabledColor: UIColor = .foregroundOnEmphasis
    var fontWeight: UIFont.Weight = .regular
    var fontSize: CGFloat = 16
    var iconSize: CGFloat = 20
    var titleImagePadding: CGFloat = 8
    var contentInset: UIEdgeInsets? = nil
    var cornersStyle: CornersStyle = .capsule
    var font: UIFont { .currentFont(withSize: fontSize, weight: fontWeight) }
    // Large
    static let largePrimaryButtonConfiguration: UDButtonConfiguration = .init(backgroundHighlightedColor: .backgroundAccentEmphasis2,
                                                                              backgroundDisabledColor: .backgroundAccent,
                                                                              textDisabledColor: .foregroundOnEmphasisOpacity,
                                                                              fontWeight: .semibold,
                                                                              cornersStyle: .custom(12))
    
    static let largeGhostPrimaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                                   backgroundHighlightedColor: .backgroundMuted,
                                                                                   backgroundDisabledColor: .clear,
                                                                                   textColor: .foregroundAccent,
                                                                                   textHighlightedColor: .foregroundAccent,
                                                                                   textDisabledColor: .foregroundAccentMuted,
                                                                                   fontWeight: .semibold,
                                                                                   cornersStyle: .custom(12))
    static let secondaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                           backgroundHighlightedColor: .backgroundSubtle,
                                                                           backgroundDisabledColor: .clear,
                                                                           textColor: .foregroundAccent,
                                                                           textHighlightedColor: .foregroundAccent,
                                                                           textDisabledColor: .foregroundAccentMuted,
                                                                           fontWeight: .semibold,
                                                                           cornersStyle: .custom(12))
    
    // Medium
    static func mediumGhostPrimaryButtonConfiguration(contentInset: UIEdgeInsets = .zero) -> UDButtonConfiguration {
        .init(backgroundIdleColor: .clear,
              backgroundHighlightedColor: .clear,
              backgroundDisabledColor: .clear,
              textColor: .foregroundAccent,
              textHighlightedColor: .foregroundAccentMuted,
              textDisabledColor: .foregroundAccentMuted,
              fontWeight: .medium,
              contentInset: contentInset)
    }
    
    static let mediumGhostTertiaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                                     backgroundHighlightedColor: .clear,
                                                                                     backgroundDisabledColor: .clear,
                                                                                     textColor: .foregroundSecondary,
                                                                                     textHighlightedColor: .foregroundMuted,
                                                                                     textDisabledColor: .foregroundMuted,
                                                                                     fontWeight: .medium)
    
    static let MediumButtonContentInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    static let mediumRaisedPrimaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .backgroundAccentEmphasis,
                                                                                     backgroundHighlightedColor: .backgroundAccentEmphasis2,
                                                                                     backgroundDisabledColor: .backgroundAccent.withAlphaComponent(0.16),
                                                                                     textColor: .foregroundOnEmphasis,
                                                                                     textHighlightedColor: .foregroundOnEmphasis,
                                                                                     textDisabledColor: .foregroundOnEmphasis.withAlphaComponent(0.56),
                                                                                     fontWeight: .medium,
                                                                                     contentInset: UDButtonConfiguration.MediumButtonContentInset)
    
    static let mediumRaisedWhiteButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .brandWhite,
                                                                                           backgroundHighlightedColor: .brandWhite.withAlphaComponent(0.64),
                                                                                           backgroundDisabledColor: .brandWhite.withAlphaComponent(0.16),
                                                                                           textColor: .brandBlack,
                                                                                           textHighlightedColor: .brandBlack,
                                                                                           textDisabledColor: .brandBlack,
                                                                                           fontWeight: .medium,
                                                                                           contentInset: UDButtonConfiguration.MediumButtonContentInset)
    
    static let mediumRaisedTertiaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .backgroundMuted2,
                                                                                      backgroundHighlightedColor: .backgroundMuted,
                                                                                      backgroundDisabledColor: .backgroundSubtle,
                                                                                      textColor: .foregroundDefault,
                                                                                      textHighlightedColor: .foregroundDefault,
                                                                                      textDisabledColor: .foregroundMuted,
                                                                                      fontWeight: .medium,
                                                                                      contentInset: UDButtonConfiguration.MediumButtonContentInset)
    
    // Small
    static let smallGhostPrimaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                                   backgroundHighlightedColor: .clear,
                                                                                   backgroundDisabledColor: .clear,
                                                                                   textColor: .foregroundAccent,
                                                                                   textHighlightedColor: .foregroundAccentMuted,
                                                                                   textDisabledColor: .foregroundAccentMuted,
                                                                                   fontWeight: .medium,
                                                                                   fontSize: 14,
                                                                                   iconSize: 16)
    static let smallGhostPrimaryWhiteButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                                        backgroundHighlightedColor: .clear,
                                                                                        backgroundDisabledColor: .clear,
                                                                                        textColor: .brandWhite,
                                                                                        textHighlightedColor: .brandWhite.withAlphaComponent(0.32),
                                                                                        textDisabledColor: .brandWhite.withAlphaComponent(0.24),
                                                                                        fontWeight: .medium,
                                                                                        fontSize: 14,
                                                                                        iconSize: 16)
    
    // Very small
    static let verySmallGhostTertiaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                                        backgroundHighlightedColor: .clear,
                                                                                        backgroundDisabledColor: .clear,
                                                                                        textColor: .foregroundSecondary,
                                                                                        textHighlightedColor: .foregroundMuted,
                                                                                        textDisabledColor: .foregroundMuted,
                                                                                        fontWeight: .medium,
                                                                                        fontSize: 12,
                                                                                        iconSize: 12,
                                                                                        titleImagePadding: 4)
    
    enum CornersStyle {
        case capsule
        case custom(CGFloat)
    }
}

