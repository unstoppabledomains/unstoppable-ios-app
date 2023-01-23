//
//  WalletConnectedViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 03.04.2022.
//

import UIKit

protocol WalletConnectedViewControllerProtocol: BaseViewControllerProtocol {
    func setPrimaryButtonTitle(_ title: String)
    func setWalletAddress(_ address: String)
    func setWalletIcon(_ icon: UIImage)
}

final class WalletConnectedViewController: BaseViewController {

    @IBOutlet private weak var walletIconImageView: UIImageView!
    @IBOutlet private weak var walletAddressLabel: UILabel!
    @IBOutlet private weak var walletConnectedLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var continueButton: MainButton!

    var presenter: WalletConnectedPresenterProtocol!
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }

    static func instantiate() -> WalletConnectedViewController {
        WalletConnectedViewController.nibInstance()
    }
    
    override var isNavBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
     
        setup()
        presenter.viewDidLoad()
    }
    
}

// MARK: - WalletConnectedViewControllerProtocol
extension WalletConnectedViewController: WalletConnectedViewControllerProtocol {
    func setPrimaryButtonTitle(_ title: String) {
        continueButton.setTitle(title, image: nil)
    }

    func setWalletAddress(_ address: String) {
        walletAddressLabel.setAttributedTextWith(text: address,
                                                 font: .systemFont(ofSize: 32, weight: .bold),
                                                 textColor: .foregroundDefault,
                                                 lineHeight: 40)
    }
    
    func setWalletIcon(_ icon: UIImage) {
        walletIconImageView.image = icon
    }
}

// MARK: - Actions
private extension WalletConnectedViewController {
    @IBAction func didTapContinueButton(_ sender: MainButton) {
        logButtonPressedAnalyticEvents(button: .continue)
        presenter.didTapContinueButton()
    }
}

// MARK: - Setup methods
private extension WalletConnectedViewController {
    func setup() {
        localiseContent()
    }
    
    func localiseContent() {
        continueButton.setTitle(String.Constants.continue.localized(), image: nil)
        walletConnectedLabel.setAttributedTextWith(text: String.Constants.walletConnected.localized(), font: .currentFont(withSize: 32, weight: .bold), textColor: .foregroundSecondary)
        descriptionLabel.setAttributedTextWith(text: String.Constants.externalWalletConnectedSubtitle.localized(), font: .currentFont(withSize: 16, weight: .regular), textColor: .foregroundSecondary)
    }
}
