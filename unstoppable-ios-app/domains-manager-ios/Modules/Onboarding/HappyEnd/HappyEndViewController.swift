//
//  HappyEndViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 23.03.2022.
//

import UIKit

@MainActor
protocol HappyEndViewControllerProtocol: BaseViewControllerProtocol {
    func setAgreement(visible: Bool)
    func setConfiguration(_ configuration: HappyEndViewController.Configuration)
}

final class HappyEndViewController: BaseViewController {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var confettiImageView: ConfettiImageView!
    @IBOutlet private weak var agreementTextView: UITextView!
    @IBOutlet private weak var getStartedButton: MainButton!
    @IBOutlet private weak var agreementStackView: UIStackView!
    
    private let termsOfUseText = String.Constants.termsOfUse.localized()
    private let privacyPolicyText = String.Constants.privacyPolicy.localized()
    override var isNavBarHidden: Bool { true }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    var presenter: HappyEndViewPresenterProtocol!

    static func instance() -> HappyEndViewController {
        HappyEndViewController.storyboardInstance(from: .happyEnd)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        confettiImageView.startConfettiAnimationAsync()
        presenter.viewWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Vibration.success.vibrate()
        presenter.viewDidAppear()
    }
    
}

// MARK: - HappyEndViewControllerProtocol
extension HappyEndViewController: HappyEndViewControllerProtocol {
    func setAgreement(visible: Bool) {
        agreementStackView.isHidden = !visible
    }
    
    func setConfiguration(_ configuration: HappyEndViewController.Configuration) {
        titleLabel.setTitle(configuration.title)
        subtitleLabel.setSubtitle(configuration.subtitle)
        getStartedButton.setTitle(configuration.actionButtonTitle, image: nil)
    }
}

// MARK: - Actions
private extension HappyEndViewController {
    @IBAction func didTapGetStartedButton(_ sender: MainButton) {
        presenter.actionButtonPressed()
        logButtonPressedAnalyticEvents(button: .getStarted)
    }
    
    @objc func didTapAgreementTextView(_ tapGesture: UITapGestureRecognizer) {
        let point = tapGesture.location(in: agreementTextView)
        if let detectedWord = getWordAtPosition(point) {
            if termsOfUseText.contains(detectedWord),
               let url = String.Links.termsOfUse.url {
                logButtonPressedAnalyticEvents(button: .termsOfUse)
                WebViewController.show(in: self, withURL: url)
            } else if privacyPolicyText.contains(detectedWord),
                      let url = String.Links.privacyPolicy.url {
                logButtonPressedAnalyticEvents(button: .privacyPolicy)
                WebViewController.show(in: self, withURL: url)
            }
        }
    }
    
    func getWordAtPosition(_ point: CGPoint) -> String? {
        if let textPosition = agreementTextView.closestPosition(to: point) {
            if let range = agreementTextView.tokenizer.rangeEnclosingPosition(textPosition,
                                                                              with: .word,
                                                                              inDirection: UITextDirection(rawValue: 1)) {
                return agreementTextView.text(in: range)
            }
        }
        return nil
    }
}

// MARK: - Setup methods
private extension HappyEndViewController {
    func setup() {
        localizeContent()
        agreementTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAgreementTextView)))
        
        getStartedButton.accessibilityIdentifier = "Happy End Get Started Button"
    }
    
    func localizeContent() {
        agreementTextView.isUserInteractionEnabled = true
        agreementTextView.textAlignment = .center
        agreementTextView.setAttributedTextWith(text: String.Constants.agreeToTUAndPP.localized(),
                                                font: .currentFont(withSize: 13, weight: .regular),
                                                textColor: .foregroundSecondary,
                                                lineHeight: 20)
        agreementTextView.updateAttributesOf(text: termsOfUseText,
                                             withFont: .currentFont(withSize: 13, weight: .medium),
                                             textColor: .foregroundDefault)
        agreementTextView.updateAttributesOf(text: privacyPolicyText,
                                             withFont: .currentFont(withSize: 13, weight: .medium),
                                             textColor: .foregroundDefault)
    }
}

// MARK: - Open methods
extension HappyEndViewController {
    struct Configuration {
        let title: String
        let subtitle: String
        let actionButtonTitle: String
        
        static let onboarding = Configuration(title: String.Constants.youAreAllDoneTitle.localized(),
                                              subtitle: String.Constants.youAreAllDoneSubtitle.localized(),
                                              actionButtonTitle: String.Constants.getStarted.localized())
        
        static let domainsPurchased = Configuration(title: String.Constants.youAreAllDoneTitle.localized(),
                                              subtitle: String.Constants.domainsPurchasedSubtitle.localized(),
                                              actionButtonTitle: String.Constants.goToDomains.localized())
    }
}

@available(iOS 17, *)
#Preview {
    let vc = HappyEndViewController.instance()
    let presenter = OnboardingHappyEndViewPresenter(view: vc)
    vc.presenter = presenter
    return vc
}

import SwiftUI
struct PurchaseDomainsHappyEndViewControllerWrapper: UIViewControllerRepresentable {
        
    weak var viewModel: PurchaseDomainsViewModel?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = HappyEndViewController.instance()
        let presenter = PurchaseDomainsHappyEndViewPresenter(view: vc)
        presenter.purchaseDomainsViewModel = viewModel
        vc.presenter = presenter
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
}
