//
//  InviteFriendsViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2023.
//

import UIKit

@MainActor
protocol InviteFriendsViewProtocol: BaseViewControllerProtocol {

}

@MainActor
final class InviteFriendsViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var copyLinkButton: UDConfigurableButton!
    @IBOutlet private weak var shareButton: MainButton!
    @IBOutlet private weak var stepsStackView: UIStackView!
    
    
    
    var presenter: InviteFriendsViewPresenterProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
   
}

// MARK: - InviteFriendsViewProtocol
extension InviteFriendsViewController: InviteFriendsViewProtocol {

}

// MARK: - Actions
private extension InviteFriendsViewController {
    @IBAction func copyLinkButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .copyLink)
        presenter.copyLinkButtonPressed()
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .share)
        presenter.shareButtonPressed()
    }
    
    @objc func infoButtonPressed() {
        logButtonPressedAnalyticEvents(button: .inviteFriendInfo)
        presenter.infoButtonPressed()
    }
}

// MARK: - Private functions
private extension InviteFriendsViewController {

}

// MARK: - Setup functions
private extension InviteFriendsViewController {
    func setup() {
        view.backgroundColor = .backgroundDefault
        localizeContent()
        setupNavigationItems()
        setupSteps()
    }
    
    func localizeContent() {
        copyLinkButton.setConfiguration(.largeGhostPrimaryButtonConfiguration)
        copyLinkButton.setTitle(String.Constants.copyLink.localized(), image: nil)
        shareButton.setTitle(String.Constants.share.localized(), image: nil)
        
        titleLabel.setTitle(String.Constants.inviteFriendsTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.inviteFriendsSubtitle.localized())
    }
    
    func setupNavigationItems() {
        let infoButton = UIBarButtonItem(image: .helpCircleIcon24,
                                         style: .plain,
                                         target: self, action: #selector(infoButtonPressed))
        infoButton.tintColor = .foregroundDefault
        navigationItem.rightBarButtonItem = infoButton
    }
    
    func setupSteps() {
        stepsStackView.removeArrangedSubviews()
        
        let steps = InviteFriendStep.allCases
        
        for step in steps {
            let stepView = InviteFriendStepView(frame: .zero)
            stepView.translatesAutoresizingMaskIntoConstraints = false
            stepsStackView.addArrangedSubview(stepView)
            stepView.setWithStep(step)
        }
    }
}

extension InviteFriendsViewController {
    enum InviteFriendStep: Int, CaseIterable {
        case step1 = 1
        case step2 = 2
        case step3 = 3
        
        var message: String {
            switch self {
            case .step1:
                return String.Constants.inviteFriendsStep1Message.localized()
            case .step2:
                return String.Constants.inviteFriendsStep2Message.localized()
            case .step3:
                return String.Constants.inviteFriendsStep3Message.localized()
            }
        }
    }
}
