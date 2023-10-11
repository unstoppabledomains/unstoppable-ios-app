//
//  SecurityWallViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.04.2022.
//

import UIKit

final class SecurityWallViewController: BaseViewController {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var settingsButton: MainButton!
    @IBOutlet private weak var protectImageview: UIImageView!
    
    static func instantiate() -> SecurityWallViewController {
        let vc = SecurityWallViewController.nibInstance()
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .fullScreen
        
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
}

// MARK: - Actions
private extension SecurityWallViewController {
    @IBAction func settingsButtonPressed(_ sender: Any) {
        if appContext.authentificationService.biometricType == .touchID,
           let url = URL(string: "App-prefs:"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Setup methods
private extension SecurityWallViewController {
    func setup() {
        localizeContent()
    }
    
    func localizeContent() {
        protectImageview.image = appContext.authentificationService.biometricIcon

        let bioName = appContext.authentificationService.biometricsName ?? ""
        titleLabel.setTitle(String.Constants.securityWallMessage.localized(bioName))
        settingsButton.setTitle(String.Constants.goToSettings.localized(), image: nil)
    }
}
