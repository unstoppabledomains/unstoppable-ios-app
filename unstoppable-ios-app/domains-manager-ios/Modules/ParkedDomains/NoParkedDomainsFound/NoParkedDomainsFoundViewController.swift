//
//  NoParkedDomainsFoundViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2023.
//

import UIKit

@MainActor
protocol NoParkedDomainsFoundViewProtocol: BaseViewControllerProtocol {

}

@MainActor
final class NoParkedDomainsFoundViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var confirmButton: MainButton!

    var presenter: NoParkedDomainsFoundViewPresenterProtocol!
    override var analyticsName: Analytics.ViewName { .noParkedDomainsFound }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        cNavigationBar?.setBackButton(hidden: true)
    }
}

// MARK: - NoParkedDomainsFoundViewProtocol
extension NoParkedDomainsFoundViewController: NoParkedDomainsFoundViewProtocol {

}

// MARK: - Actions
private extension NoParkedDomainsFoundViewController {
    @IBAction func confirmButtonPressed(_ sender: Any) {
        presenter.confirmButtonPressed()
    }
}

// MARK: - Private functions
private extension NoParkedDomainsFoundViewController {

}

// MARK: - Setup functions
private extension NoParkedDomainsFoundViewController {
    func setup() {
        confirmButton.setTitle(String.Constants.gotIt.localized(), image: nil)
        titleLabel.setTitle(String.Constants.noParkedDomainsTitle.localized())
    }
}
