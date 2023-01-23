//
//  UDConfigurableButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.12.2022.
//

import UIKit

class UDConfigurableButton: BaseButton {
    private var pUdConfiguration: UDConfiguration = .primaryButtonConfiguration
    var udConfiguration: UDConfiguration { pUdConfiguration }
    
    override var backgroundIdleColor: UIColor { udConfiguration.backgroundIdleColor }
    override var backgroundHighlightedColor: UIColor { udConfiguration.backgroundHighlightedColor }
    override var backgroundDisabledColor: UIColor { udConfiguration.backgroundDisabledColor }
    
    override var textColor: UIColor { udConfiguration.textColor }
    override var textHighlightedColor: UIColor { udConfiguration.textHighlightedColor }
    override var textDisabledColor: UIColor { udConfiguration.textDisabledColor }
    override var fontWeight: UIFont.Weight { customFontWeight ?? udConfiguration.fontWeight }
    var customFontWeight: UIFont.Weight?

    func setConfiguration(_ configuration: UDConfiguration) {
        self.pUdConfiguration = configuration
        isEnabled.toggle()
        isEnabled.toggle()
    }
}

extension UDConfigurableButton {
    struct UDConfiguration {
        var backgroundIdleColor: UIColor = .backgroundAccentEmphasis
        var backgroundHighlightedColor: UIColor = .backgroundAccentEmphasis
        var backgroundDisabledColor: UIColor = .backgroundAccentEmphasis
        var textColor: UIColor = .foregroundOnEmphasis
        var textHighlightedColor: UIColor = .foregroundOnEmphasis
        var textDisabledColor: UIColor = .foregroundOnEmphasis
        var fontWeight: UIFont.Weight = .regular
        
        static let primaryButtonConfiguration: UDConfiguration = .init(backgroundHighlightedColor: .backgroundAccentEmphasis2,
                                                                       backgroundDisabledColor: .backgroundAccent,
                                                                       textDisabledColor: .foregroundOnEmphasisOpacity,
                                                                       fontWeight: .semibold)
        
        static let secondaryButtonConfiguration: UDConfiguration = .init(backgroundIdleColor: .clear,
                                                                         backgroundHighlightedColor: .backgroundSubtle,
                                                                         backgroundDisabledColor: .clear,
                                                                         textColor: .foregroundAccent,
                                                                         textHighlightedColor: .foregroundAccent,
                                                                         textDisabledColor: .foregroundAccentMuted,
                                                                         fontWeight: .semibold)
        
        static let tertiaryButtonConfiguration: UDConfiguration = .init(backgroundIdleColor: .backgroundMuted2,
                                                                        backgroundHighlightedColor: .backgroundMuted,
                                                                        backgroundDisabledColor: .backgroundSubtle,
                                                                        textColor: .foregroundDefault,
                                                                        textHighlightedColor: .foregroundDefault,
                                                                        textDisabledColor: .foregroundMuted,
                                                                        fontWeight: .semibold)
    }
}

