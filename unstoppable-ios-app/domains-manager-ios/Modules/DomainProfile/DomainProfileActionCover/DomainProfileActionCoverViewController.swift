//
//  DomainProfileActionCoverViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.11.2022.
//

import UIKit

@MainActor
protocol DomainProfileActionCoverViewProtocol: BaseViewControllerProtocol {
    func setPrimaryButton(with description: DomainProfileActionCoverViewController.ActionButtonDescription)
    func setSecondaryButton(with description: DomainProfileActionCoverViewController.ActionButtonDescription?)
    func set(title: String, domainName: String, description: String)
    func set(avatarImage: UIImage?, avatarStyle: DomainAvatarImageView.AvatarStyle, backgroundImage: UIImage?)
}

@MainActor
final class DomainProfileActionCoverViewController: BaseViewController {
    
    
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var backgroundImageBlurView: UIVisualEffectView!
    @IBOutlet private weak var avatarImageView: DomainAvatarImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var primaryButton: PrimaryWhiteButton!
    @IBOutlet private weak var secondaryButton: RaisedTertiaryWhiteButton!
    
    var presenter: DomainProfileActionCoverViewPresenterProtocol!
    override var navBackStyle: NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var navBackButtonConfiguration: CNavigationBarContentView.BackButtonConfiguration {
        .init(backArrowIcon: BaseViewController.NavBackIconStyle.cancel.icon,
              tintColor: .foregroundOnEmphasis,
              backTitleVisible: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
    override func shouldPopOnBackButton() -> Bool {
        presenter.shouldPopOnBackButton()
    }
    
}

// MARK: - DomainProfileActionCoverViewProtocol
extension DomainProfileActionCoverViewController: DomainProfileActionCoverViewProtocol {
    func setPrimaryButton(with description: ActionButtonDescription) {
        set(button: primaryButton, with: description)
    }
    
    func setSecondaryButton(with description: ActionButtonDescription?) {
        secondaryButton.isHidden = description == nil
        if let description {
            set(button: secondaryButton, with: description)
        }
    }
    
    func set(title: String, domainName: String, description: String) {
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 22, weight: .bold),
                                         textColor: .white,
                                         lineBreakMode: .byTruncatingTail)
        domainNameLabel.setAttributedTextWith(text: domainName,
                                              font: .currentFont(withSize: 22, weight: .bold),
                                              textColor: .white.withAlphaComponent(0.56),
                                              lineBreakMode: .byTruncatingTail)
        descriptionLabel.setAttributedTextWith(text: description,
                                               font: .currentFont(withSize: 16, weight: .regular),
                                               textColor: .white.withAlphaComponent(0.56))
    }

    func set(avatarImage: UIImage?, avatarStyle: DomainAvatarImageView.AvatarStyle, backgroundImage: UIImage?) {
        avatarImageView.image = avatarImage
        avatarImageView.setAvatarStyle(avatarStyle)
        backgroundImageView.image = backgroundImage
        backgroundImageBlurView.isHidden = backgroundImage == nil
    }
}

// MARK: - Actions
private extension DomainProfileActionCoverViewController {
    @IBAction func primaryButtonPressed(_ sender: Any) {
        presenter.primaryButtonDidPress()
    }
    
    @IBAction func secondaryButtonPressed(_ sender: Any) {
        presenter.secondaryButtonDidPress()
    }
}

// MARK: - Private functions
private extension DomainProfileActionCoverViewController {
    func set(button: BaseButton, with description: ActionButtonDescription) {
        button.setTitle(description.title,
                        image: description.icon)
    }
}

// MARK: - Setup functions
private extension DomainProfileActionCoverViewController {
    func setup() {
        view.backgroundColor = .brandUnstoppableBlue
    }
}

extension DomainProfileActionCoverViewController {
    struct ActionButtonDescription {
        let title: String
        let icon: UIImage
    }
}
