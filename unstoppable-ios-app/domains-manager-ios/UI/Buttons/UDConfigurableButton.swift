//
//  UDConfigurableButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.12.2022.
//

import UIKit

class UDConfigurableButton: BaseButton {
    private var pUdConfiguration: UDButtonConfiguration = .largePrimaryButtonConfiguration
    var udConfiguration: UDButtonConfiguration { pUdConfiguration }
    
    override var backgroundIdleColor: UIColor { udConfiguration.backgroundIdleColor }
    override var backgroundHighlightedColor: UIColor { udConfiguration.backgroundHighlightedColor }
    override var backgroundDisabledColor: UIColor { udConfiguration.backgroundDisabledColor }
    
    override var textColor: UIColor { udConfiguration.textColor }
    override var textHighlightedColor: UIColor { udConfiguration.textHighlightedColor }
    override var textDisabledColor: UIColor { udConfiguration.textDisabledColor }
    override var fontWeight: UIFont.Weight { customFontWeight ?? udConfiguration.fontWeight }
    var customFontWeight: UIFont.Weight?

    func setConfiguration(_ configuration: UDButtonConfiguration) {
        self.pUdConfiguration = configuration
        isEnabled.toggle()
        isEnabled.toggle()
    }
}
