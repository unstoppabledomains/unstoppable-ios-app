//
//  MintDomainsConfigurationSetPrimaryCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

typealias SetIsPrimaryDomainCallback = (Bool)->()

final class MintDomainsConfigurationSetPrimaryCell: BaseListCollectionViewCell {

    @IBOutlet private weak var infoButton: TextBlackButton!
    @IBOutlet private weak var switcher: UISwitch!
    
    private var infoPressedCallback: EmptyCallback?
    private var valueChangedCallback: SetIsPrimaryDomainCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        infoButton.imageLayout = .trailing
        infoButton.setTitle(String.Constants.setAsMyPrimaryDomain.localized(), image: .infoIcon16)
        infoButton.titleLabel?.numberOfLines = 0
    }
  
}

// MARK: - Open methods
extension MintDomainsConfigurationSetPrimaryCell {
    func set(isOn: Bool, isEnabled: Bool, infoPressedCallback: EmptyCallback?, valueChangedCallback: SetIsPrimaryDomainCallback?) {
        self.switcher.isOn = isOn
        self.switcher.isEnabled = isEnabled
        self.infoPressedCallback = infoPressedCallback
        self.valueChangedCallback = valueChangedCallback
    }
}

// MARK: - Private methods
private extension MintDomainsConfigurationSetPrimaryCell {
    @IBAction func switcherValueChanged(_ sender: Any) {
        valueChangedCallback?(switcher.isOn)
    }
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        infoPressedCallback?()
    }
}
