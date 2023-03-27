//
//  LoadingParkedDomainsViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2023.
//

import UIKit

@MainActor
protocol LoadingParkedDomainsViewProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {

}

@MainActor
final class LoadingParkedDomainsViewController: BaseViewController {
    
    @IBOutlet private weak var syncingLabel: UILabel!
    var presenter: LoadingParkedDomainsViewPresenterProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
        Task { @MainActor in
            setDashesProgress(nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        cNavigationBar?.setBackButton(hidden: true)
    }
}

// MARK: - LoadingParkedDomainsViewProtocol
extension LoadingParkedDomainsViewController: LoadingParkedDomainsViewProtocol {
    var progress: Double? { nil }
}

// MARK: - Private functions
private extension LoadingParkedDomainsViewController {

}

// MARK: - Setup functions
private extension LoadingParkedDomainsViewController {
    func setup() {
        addProgressDashesView()
        syncingLabel.setAttributedTextWith(text: String.Constants.syncing.localized() + "...",
                                           font: .currentFont(withSize: 16, weight: .semibold),
                                           textColor: .foregroundDefault)
    }
}
