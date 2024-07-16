//
//  ParkedDomainsFoundViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import UIKit

@MainActor
protocol ParkedDomainsFoundViewProtocol: ViewWithDashesProgress{
    func setWith(email: String, numberOfDomainsFound: Int)
}

@MainActor
final class ParkedDomainsFoundViewController: BaseViewController {
    
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var importButton: MainButton!
    
    var presenter: ParkedDomainsFoundViewPresenterProtocol!
    override var analyticsName: Analytics.ViewName { .parkedDomainsList }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
}

// MARK: - ParkedDomainsFoundViewProtocol
extension ParkedDomainsFoundViewController: ParkedDomainsFoundViewProtocol {
    var progress: Double? { presenter.progress }

    func setWith(email: String, numberOfDomainsFound: Int) {
        emailLabel.setAttributedTextWith(text: email,
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .foregroundSuccess)
        titleLabel.setTitle(String.Constants.pluralNParkedDomainsImported.localized(numberOfDomainsFound, numberOfDomainsFound))
    }
}

// MARK: - Private functions
private extension ParkedDomainsFoundViewController {
    @IBAction func importButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .confirm)
        presenter.importButtonPressed()
    }
}

// MARK: - Setup functions
private extension ParkedDomainsFoundViewController {
    func setup() {
        addProgressDashesView()
        importButton.setTitle(String.Constants.viewVaultedDomains.localized(), image: nil)
    }
    
}

@available(iOS 17.0, *)
#Preview {
    let vc = ParkedDomainsFoundViewController.nibInstance()
    let manager = PreviewLoginManager()
    let presenter = ParkedDomainsFoundInAppViewPresenter(view: vc,
                                                         domains: MockEntitiesFabric.Domains.mockFirebaseDomainsDisplayInfo(),
                                                         loginFlowManager: manager)
    vc.presenter = presenter
    
    return vc
}

private final class PreviewLoginManager: LoginFlowManager {
    func handle(action: LoginFlowNavigationController.Action) async throws { }
}
