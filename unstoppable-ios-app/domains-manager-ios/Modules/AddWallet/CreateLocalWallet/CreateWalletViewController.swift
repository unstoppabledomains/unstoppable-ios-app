//
//  CreateWalletViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.03.2022.
//

import UIKit

@MainActor
protocol CreateWalletViewControllerProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    func setStyle(_ style: CreateWalletViewController.Style)
    func setActivityIndicator(active: Bool)
    func setNavigationGestureEnabled(_ isEnabled: Bool)
}

final class CreateWalletViewController: BaseViewController {
    
    @IBOutlet private weak var loadingStateStackView: UIStackView!
    @IBOutlet private weak var creatingWalletLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var createVaultButton: MainButton!
    @IBOutlet private weak var fullUIStateStackView: UIStackView!
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    
    private var style: Style = .fullUI
    var presenter: CreateWalletPresenterProtocol!
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .createWallet }
    override var isNavBarHidden: Bool { style == .progressIndicator }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }

    static func instantiate() -> CreateWalletViewController {
        CreateWalletViewController.nibInstance()
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        presenter.viewDidAppear()
    }
    
    override func shouldPopOnBackButton() -> Bool {
        presenter.canMoveBack
    }
}

// MARK: - CreateWalletViewControllerProtocol
extension CreateWalletViewController: CreateWalletViewControllerProtocol {
    var progress: Double? { style == .progressIndicator ? nil : 0.25 }

    func setStyle(_ style: CreateWalletViewController.Style) {
        self.style = style
        switch style {
        case .fullUI:
            loadingStateStackView.isHidden = true
            fullUIStateStackView.isHidden = false
        case .progressIndicator:
            loadingStateStackView.isHidden = false
            fullUIStateStackView.isHidden = true
        }
        createVaultButton.isHidden = fullUIStateStackView.isHidden
    }
    
    func setActivityIndicator(active: Bool) {
        if active {
            createVaultButton.setTitle(String.Constants.creatingWallet.localized(), image: nil)
            createVaultButton.showLoadingIndicator()
            activityIndicator.startAnimating()
        } else {
            createVaultButton.setTitle(String.Constants.createVault.localized(), image: nil)
            createVaultButton.hideLoadingIndicator()
            activityIndicator.stopAnimating()
        }
    }
    
    func setNavigationGestureEnabled(_ isEnabled: Bool) {
        cNavigationController?.transitionHandler?.isInteractionEnabled = isEnabled
    }
}

// MARK: - Actions
private extension CreateWalletViewController {
    @IBAction func createVaultButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .createVault)
        presenter.createVaultButtonPressed()
    }
}

// MARK: - Setup methods
private extension CreateWalletViewController {
    func setup() {
        setStyle(.fullUI)
        addProgressDashesView()

        // Progress indicator
        activityIndicator.color = .foregroundDefault
        creatingWalletLabel.setAttributedTextWith(text: String.Constants.creatingWallet.localized() + "...",
                                                  font: .currentFont(withSize: 16, weight: .semibold),
                                                  textColor: .foregroundDefault)
        
        // Full UI
        createVaultButton.setTitle(String.Constants.createVault.localized(), image: nil)
        titleLabel.setTitle(String.Constants.createNewVaultTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.createNewVaultSubtitle.localized())
    }
}

// MARK: - Style
extension CreateWalletViewController {
    enum Style {
        case progressIndicator, fullUI
    }
}
