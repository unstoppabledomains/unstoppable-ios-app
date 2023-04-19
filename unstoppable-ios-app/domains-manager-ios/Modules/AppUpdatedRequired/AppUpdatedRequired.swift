//
//  AppUpdatedRequired.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.06.2022.
//

import UIKit

final class AppUpdatedRequired: BaseViewController {

    @IBOutlet weak var titleLabel: UDTitleLabel!
    @IBOutlet weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet weak var updateButton: MainButton!
    override var analyticsName: Analytics.ViewName { .appUpdateRequired }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
}

// MARK: - Private methods
private extension AppUpdatedRequired {
    @IBAction func updateButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .update)
        let info = User.instance.getAppVersionInfo()
        if let url = URL(string: info.supportedStoreLink), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }
}

// MARK: - Setup methods
private extension AppUpdatedRequired {
    func setup() {
        titleLabel.setTitle(String.Constants.appUpdateRequiredTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.appUpdateRequiredSubtitle.localized())
        updateButton.setTitle(String.Constants.update.localized(), image: nil)
    }
}
