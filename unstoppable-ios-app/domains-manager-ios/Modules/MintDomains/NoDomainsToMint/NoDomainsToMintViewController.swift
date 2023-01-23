//
//  NoDomainsToMintViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import UIKit

@MainActor
protocol NoDomainsToMintViewProtocol: BaseViewControllerProtocol {

}

@MainActor
final class NoDomainsToMintViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet weak var importButton: SecondaryButton!
    
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .noDomainsToMint }

    var presenter: NoDomainsToMintViewPresenterProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
}

// MARK: - NoDomainsToMintViewProtocol
extension NoDomainsToMintViewController: NoDomainsToMintViewProtocol {

}

// MARK: - Private functions
private extension NoDomainsToMintViewController {
    @IBAction func buyDomainButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .buyDomains)
        presenter.buyDomainButtonPressed()
    }
    
    @IBAction func importButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .importWallet)
        presenter.importButtonPressed()
    }
}

// MARK: - Setup functions
private extension NoDomainsToMintViewController {
    func setup() {
        localizeContent()
    }
    
    func localizeContent() {
        titleLabel.setTitle(String.Constants.noDomainsToMintMessage.localized())
        importButton.setTitle(String.Constants.importWallet.localized(), image: nil)
    }
}
