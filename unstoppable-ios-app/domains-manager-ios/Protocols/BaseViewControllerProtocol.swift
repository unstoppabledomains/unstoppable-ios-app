//
//  BaseViewControllerProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

@MainActor
protocol BaseViewControllerProtocol: UIViewController, ViewAnalyticsLogger & PaymentConfirmationDelegate {
    func hideKeyboard()
    func addHideKeyboardTapGesture(cancelsTouchesInView: Bool, toView v: UIView?)
    func showAlertWith(error: Error, handler: ((UIAlertAction) -> Void)?)
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    func push(_ viewController: UIViewController, animated: Bool)
    func checkKeyboardObservations()
}

extension BaseViewControllerProtocol {
    func hideKeyboard() {
        view.endEditing(true)
        cNavigationController?.view.endEditing(true)
    }
    
    func addHideKeyboardTapGesture(cancelsTouchesInView: Bool = true, toView v: UIView? = nil) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tap.cancelsTouchesInView = cancelsTouchesInView
        tap.delegate = self
        if let v = v {
            v.addGestureRecognizer(tap)
        } else {
            view.addGestureRecognizer(tap)
        }
    }
    
    func showAlertWith(error: Error, handler: ((UIAlertAction) -> Void)? = nil) {
        view.endEditing(true)
        var message: String
        let title: String
        
        if error is TransactionError {
            title = String.Constants.transactionFailed.localized()
            message = String.Constants.pleaseTryAgain.localized()
        } else if let networkError = error as? NetworkLayerError,
                case .notConnectedToInternet = networkError {
            title = String.Constants.connectionLost.localized()
            message = String.Constants.pleaseCheckInternetConnection.localized()
        } else {
            title = String.Constants.somethingWentWrong.localized()
            message = String.Constants.pleaseTryAgain.localized()
        }
        
        #if DEBUG
        message = error.localizedDescription
        #endif
        
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.Constants.ok.localized().uppercased(),
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func push(_ viewController: UIViewController, animated: Bool) {
        navigationController?.pushViewController(viewController, animated: animated)
    }
}

@objc extension UIViewController: UIGestureRecognizerDelegate {
    @objc func didTap(_ tap: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}
