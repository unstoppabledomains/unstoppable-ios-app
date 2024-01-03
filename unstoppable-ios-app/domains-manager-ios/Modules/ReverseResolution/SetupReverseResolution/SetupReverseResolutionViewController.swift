//
//  SetupReverseResolutionViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2022.
//

import UIKit

@MainActor
protocol SetupReverseResolutionViewProtocol: BaseViewControllerProtocol {
    func setWith(walletInfo: WalletDisplayInfo, domain: DomainDisplayInfo?)
    func setSkipButton(hidden: Bool)
    func setConfirmButton(title: String, icon: UIImage?)
}

@MainActor
final class SetupReverseResolutionViewController: BaseViewController {
    
    @IBOutlet private weak var rrIllustrationView: ReverseResolutionIllustrationView!
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var confirmButton: MainButton!
    @IBOutlet private weak var skipButton: SecondaryButton!
    
    var presenter: SetupReverseResolutionViewPresenterProtocol!
    override var navBackStyle: BaseViewController.NavBackIconStyle { presenter.navBackStyle }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var additionalAppearAnalyticParameters: Analytics.EventParameters {
        if let domainName = presenter.domainName {
            return [.domainName: domainName]
        }
        return [:]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
}

// MARK: - SetupReverseResolutionViewProtocol
extension SetupReverseResolutionViewController: SetupReverseResolutionViewProtocol {
    func setWith(walletInfo: WalletDisplayInfo, domain: DomainDisplayInfo?) {
        rrIllustrationView.setWith(walletInfo: walletInfo, domain: domain)
        
        if let domain = domain {
            let walletAddress = walletInfo.address.walletAddressTruncated
            let domainName = domain.name
            set(subtitle: String.Constants.setupReverseResolutionDescription.localized(domainName, walletAddress))
            subtitleLabel.updateAttributesOf(text: domainName,
                                             withFont: .currentFont(withSize: 16, weight: .medium),
                                             textColor: .foregroundDefault)
            subtitleLabel.updateAttributesOf(text: walletAddress,
                                             withFont: .currentFont(withSize: 16, weight: .medium),
                                             textColor: .foregroundDefault)
        } else {
            set(subtitle: String.Constants.reverseResolutionInfoSubtitle.localized())
        }
    }
    
    func setSkipButton(hidden: Bool) {
        skipButton.isHidden = hidden
    }

    func setConfirmButton(title: String, icon: UIImage?) {
        confirmButton.setTitle(title, image: icon)
    }
}

extension SetupReverseResolutionViewController: CNavigationControllerChildTransitioning {
    func popNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        SetupReverseResolutionNavBarPopAnimation(animationDuration: CNavigationHelper.DefaultNavAnimationDuration)
    }
}

// MARK: - Actions
private extension SetupReverseResolutionViewController {
    @IBAction func confirmButtonPressed(_ sender: Any) {
        presenter.confirmButtonPressed()
    }
    
    @IBAction func skipButtonPressed(_ sender: Any) {
        presenter.skipButtonPressed()
    }
}

// MARK: - Setup functions
private extension SetupReverseResolutionViewController {
    func setup() {
        titleLabel.setTitle(String.Constants.setupReverseResolution.localized())
        skipButton.setTitle(String.Constants.later.localized(), image: nil)
    }
    
    func set(subtitle: String) {
        subtitleLabel.setAttributedTextWith(text: subtitle,
                                            font: .currentFont(withSize: 16, weight: .regular),
                                            textColor: .foregroundSecondary,
                                            alignment: .center)
    }
}
