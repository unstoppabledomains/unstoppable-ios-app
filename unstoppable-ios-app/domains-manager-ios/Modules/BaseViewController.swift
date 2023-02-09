//
//  BaseViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.04.2022.
//

import UIKit

class BaseViewController: UIViewController, CNavigationControllerChild, ViewAnalyticsLogger {
       
    private let notificationCenter = NotificationCenter.default
    private var keyboardWillShowObserver: NSObjectProtocol?
    private var keyboardDidShowObserver: NSObjectProtocol?
    private var keyboardWillHideObserver: NSObjectProtocol?
    private(set) var keyboardFrame: CGRect = .zero
    private(set) var keyboardAnimationDuration: TimeInterval = 0.25
    private(set) var keyboardAppeared = false
    private(set) var isKeyboardOpened = false
    private(set) var isDisappearing = false
    var isObservingKeyboard: Bool { false }
    var prefersLargeTitles: Bool { false }
    var navBackStyle: NavBackIconStyle { .arrow }
    var scrollableContentYOffset: CGFloat? { nil }
    var largeTitleAlignment: NSTextAlignment { .left }
    var largeTitleIcon: UIImage? { nil }
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
                     iconTintColor: .foregroundMuted)
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
    @objc func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) { }
    @objc func keyboardDidShowAction() { }
    @objc func keyboardWillHideAction(duration: Double, curve: Int) { }
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
        if keyboardDidShowObserver == nil {
            keyboardDidShowObserver = notificationCenter.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main, using: { [weak self] (notification) in
                self?.keyboardDidShowAction()
            })
        }
        if keyboardWillShowObserver == nil {
            keyboardWillShowObserver = notificationCenter.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main, using: { [weak self] (notification) in
                guard let self = self else { return }
                
                if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    guard keyboardFrame.cgRectValue != self.keyboardFrame else { return }
                    
                    self.keyboardFrame = keyboardFrame.cgRectValue
                }
                var animationDuration: Double = 0
                if let keyboardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
                    animationDuration = keyboardAnimationDuration
                }
                var curve: Int = 0
                if let keyboardCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int {
                    curve = keyboardCurve
                }
                
                self.isKeyboardOpened = true
                self.keyboardWillShowAction(duration: animationDuration, curve: curve, keyboardHeight: self.keyboardFrame.height)
            })
        }
        if keyboardWillHideObserver == nil {
            keyboardWillHideObserver = notificationCenter.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main, using: { [weak self] (notification) in
                guard let self = self else { return }
                guard self.isKeyboardOpened else { return }
                
                self.isKeyboardOpened = false
                self.keyboardFrame = .zero
                
                var animationDuration: Double = 0
                if let keyboardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
                    animationDuration = keyboardAnimationDuration
                }
                var curve: Int = 0
                if let keyboardCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int {
                    curve = keyboardCurve
                }
                self.keyboardWillHideAction(duration: animationDuration, curve: curve)
            })
        }
    }
    
    func removeKeyboardObservers() {
        if keyboardWillShowObserver != nil {
            notificationCenter.removeObserver(keyboardWillShowObserver!)
        }
        if keyboardDidShowObserver != nil {
            notificationCenter.removeObserver(keyboardDidShowObserver!)
        }
        if keyboardWillHideObserver != nil {
            notificationCenter.removeObserver(keyboardWillHideObserver!)
        }
        
        keyboardWillShowObserver = nil
        keyboardDidShowObserver = nil
        keyboardWillHideObserver = nil
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
