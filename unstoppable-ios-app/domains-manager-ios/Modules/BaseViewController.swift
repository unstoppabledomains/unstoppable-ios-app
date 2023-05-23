//
//  BaseViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.04.2022.
//

import UIKit

class BaseViewController: UIViewController, CNavigationControllerChild, ViewAnalyticsLogger, KeyboardServiceListener {
       
    private(set) var isDisappearing = false
    
    var keyboardFrame: CGRect { KeyboardService.shared.keyboardFrame }
    var keyboardAnimationDuration: TimeInterval { KeyboardService.shared.keyboardAnimationDuration }
    var keyboardAppeared: Bool { KeyboardService.shared.keyboardAppeared }
    var isKeyboardOpened: Bool { KeyboardService.shared.isKeyboardOpened }
    var isObservingKeyboard: Bool { false }
    
    var prefersLargeTitles: Bool { false }
    var navBackStyle: NavBackIconStyle { .arrow }
    var scrollableContentYOffset: CGFloat? { nil }
    var largeTitleAlignment: NSTextAlignment { .left }
    var largeTitleIcon: UIImage? { nil }
    var largeTitleIconTintColor: UIColor { .foregroundMuted }
    var largeTitleIconSize: CGSize? { nil }
    var adjustLargeTitleFontSizeForSmallerDevice: Bool { false }
    var analyticsName: Analytics.ViewName { .unspecified }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [:] }
    var searchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration? { nil }

    // MARK: - PaymentConfirmationDelegate properties
    var stripePaymentHelper: StripePaymentHelper?
    var storedPayload: NetworkService.TxPayload?
    var storedContinuation: CheckedContinuation<NetworkService.TxPayload, Error>?
    var paymentInProgress: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addObservers()
        navigationController?.navigationBar.prefersLargeTitles = prefersLargeTitles
        customiseNavigationBackButton(image: navBackStyle.icon)
        navBarUpdated()
        cNavigationController?.backButtonPressedCallback = { [weak self] in
            UDVibration.buttonTap.vibrate()
            self?.logButtonPressedAnalyticEvents(button: .navigationBack)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard cNavigationController != nil || navigationController != nil else { return }
        super.viewDidAppear(animated)
        
        isDisappearing = false
        navigationController?.navigationBar.prefersLargeTitles = prefersLargeTitles
        customiseNavigationBackButton(image: navBackStyle.icon)
        navBarUpdated()
        appContext.externalEventsService.checkPendingEvents()
        if analyticsName == .unspecified {
            Debugger.printFailure("Did not specify screen name for \(String(describing: self))", critical: false)
        }
        logAnalytic(event: .viewDidAppear, parameters: additionalAppearAnalyticParameters)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        isDisappearing = true
        removeObservers()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        customiseNavigationBackButton(image: navBackStyle.icon)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navBarUpdated()
    }
    
    // MARK: - KeyboardServiceListener
    func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) { }
    func keyboardDidShowAction() { }
    func keyboardWillHideAction(duration: Double, curve: Int) { }
    
    // MARK: - CNavigationControllerChild
    var navBarTitleAttributes: [NSAttributedString.Key : Any]? { [.foregroundColor : UIColor.foregroundDefault,
                                                                  .font: UIFont.currentFont(withSize: 16, weight: .semibold)] }
    var largeTitleConfiguration: CNavigationBar.LargeTitleConfiguration? {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = largeTitleAlignment
        var fontSize: CGFloat = 32
        if adjustLargeTitleFontSizeForSmallerDevice,
           deviceSize == .i4Inch {
            fontSize = 28
        }
        let attributes: [NSAttributedString.Key : Any] = [.foregroundColor: UIColor.foregroundDefault,
                                                          .font: UIFont.currentFont(withSize: fontSize, weight: .bold),
                                                          .paragraphStyle : paragraphStyle]
        
        return .init(navBarLargeTitleAttributes: attributes,
                     largeTitleIcon: largeTitleIcon,
                     largeTitleIconSize: largeTitleIconSize,
                     iconTintColor: largeTitleIconTintColor)
    }
    var isNavBarHidden: Bool { false }
    var navBarDividerColor: UIColor { .borderDefault }

    var navBackButtonConfiguration: CNavigationBarContentView.BackButtonConfiguration {
        .init(backArrowIcon: navBackStyle.icon,
              tintColor: .foregroundDefault,
              backTitleVisible: false)
    }
    
    func shouldPopOnBackButton() -> Bool { true }
    func customScrollingBehaviour(yOffset: CGFloat, in navBar: CNavigationBar) -> (()->())? { nil }

}

// MARK: - BaseViewControllerProtocol
extension BaseViewController: BaseViewControllerProtocol {
    func checkKeyboardObservations() {
        removeKeyboardObservers()
        if isObservingKeyboard {
            addKeyboardObservers()
        }
    }
}

// MARK: - Open methods
extension BaseViewController {
    @objc func navBarUpdated() { }
}

// MARK: - Private functions
private extension BaseViewController {
    func addObservers() {
        if isObservingKeyboard { addKeyboardObservers() }
    }
    
    func removeObservers() {
        if isObservingKeyboard { removeKeyboardObservers() }
    }
    
    func addKeyboardObservers() {
        KeyboardService.shared.addListener(self)
    }
    
    func removeKeyboardObservers() {
        KeyboardService.shared.removeListener(self)
    }
}

// MARK: - Setup methods
private extension BaseViewController {
    func setup() {
        view.backgroundColor = .backgroundDefault
        customiseNavigationBackButton(image: navBackStyle.icon)
        navigationController?.navigationBar.isHidden = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.navigationBar.prefersLargeTitles = prefersLargeTitles
        navigationItem.setValue(true, forKey: "__largeTitleTwoLineMode")
        cNavigationController?.navigationBar.navBarContentView.backButton.accessibilityIdentifier = "Navigation Back Button"
        navBarUpdated()
    }
}

extension BaseViewController {
    enum NavBackIconStyle {
        case arrow, cancel
        
        var icon: UIImage {
            switch self {
            case .arrow:
                return .navArrowLeft
            case .cancel:
                return .cancelIcon
            }
        }
    }
}
