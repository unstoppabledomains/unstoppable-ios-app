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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
}

// MARK: - NoParkedDomainsFoundViewProtocol
extension NoParkedDomainsFoundViewController: NoParkedDomainsFoundViewProtocol {

}

// MARK: - Private functions
private extension NoParkedDomainsFoundViewController {

}

// MARK: - Setup functions
private extension NoParkedDomainsFoundViewController {
    func setup() {
        
    }
}
