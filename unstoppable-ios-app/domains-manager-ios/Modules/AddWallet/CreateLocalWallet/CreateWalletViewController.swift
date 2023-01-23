//
//  CreateWalletViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.03.2022.
//

import UIKit

protocol CreateWalletViewControllerProtocol: BaseViewControllerProtocol {
    func setActivityIndicator(active: Bool)
}

final class CreateWalletViewController: BaseViewController {
    
    @IBOutlet private weak var creatingWalletLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var didAppear = false
    var presenter: CreateWalletPresenterProtocol!
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .createWallet }
    override var isNavBarHidden: Bool { true }
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
    
        if !didAppear {
            presenter.viewDidAppear()
            didAppear = true
        }
    }
}

// MARK: - CreateWalletViewControllerProtocol
extension CreateWalletViewController: CreateWalletViewControllerProtocol {
    func setActivityIndicator(active: Bool) {
        if active {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}

// MARK: - Setup methods
private extension CreateWalletViewController {
    func setup() {
        activityIndicator.color = .foregroundDefault
        creatingWalletLabel.setAttributedTextWith(text: String.Constants.creatingWallet.localized(),
                                                  font: .currentFont(withSize: 16, weight: .semibold),
                                                  textColor: .foregroundDefault)
    }
}
