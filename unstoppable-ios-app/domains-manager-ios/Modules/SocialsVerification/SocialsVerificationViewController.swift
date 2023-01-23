//
//  SocialsVerificationViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import UIKit

@MainActor
protocol SocialsVerificationViewProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    func setWith(socialType: SocialsType, value: String)
}

@MainActor
final class SocialsVerificationViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var socialValueLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var verifyButton: MainButton!
    
    var presenter: SocialsVerificationViewPresenterProtocol!
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
  
}

// MARK: - SocialsVerificationViewProtocol
extension SocialsVerificationViewController: SocialsVerificationViewProtocol {
    var progress: Double? { presenter.progress }

    func setWith(socialType: SocialsType, value: String) {
        verifyButton.setTitle(String.Constants.verify.localized(), image: socialType.icon)
        socialValueLabel.setAttributedTextWith(text: value,
                                               font: titleLabel.font,
                                               textColor: .foregroundSecondary)
        descriptionLabel.setAttributedTextWith(text: String.Constants.socialsVerifyAccountDescription.localized(socialType.title),
                                               font: .currentFont(withSize: 16, weight: .regular),
                                               textColor: .foregroundSecondary)
    }
}

// MARK: - Actions
private extension SocialsVerificationViewController {
    @IBAction func verifyButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .verify)
    }
}

// MARK: - Private functions
private extension SocialsVerificationViewController {

}

// MARK: - Setup functions
private extension SocialsVerificationViewController {
    func setup() {
        addProgressDashesView()
        titleLabel.setTitle(String.Constants.socialsVerifyAccountTitle.localized())
    }
}
