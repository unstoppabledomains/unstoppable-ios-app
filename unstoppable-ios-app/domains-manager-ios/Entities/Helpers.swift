//
//  Helpers.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 03.10.2020.
//

import Foundation
import UIKit


protocol SelfNameable { }
extension SelfNameable {
    static var name: String { return String(describing: Self.self) }
}

// Helps to instantiate Nibs
protocol NibInstantiateable where Self: UIView {
    var containerView: UIView! { get }
}

extension NibInstantiateable{
    func commonViewInit(nibName: String? = nil) {
        let name = nibName ?? String(describing: type(of: self))
        let nib = UINib(nibName: name, bundle: .main)
        nib.instantiate(withOwner: self, options: nil)
        self.addSubview(self.containerView)
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.containerView.topAnchor.constraint(equalTo: self.topAnchor),
            self.containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
}


struct KeyboardSizeManager {
    let notification: NSNotification
    let kbdSize: CGSize
    init? (notification: NSNotification) {
        self.notification = notification
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return nil }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        self.kbdSize = keyboardScreenEndFrame.size
    }
}

extension Error {
    func getTypedDescription() -> String {
        if let error = self as? RawValueLocalizable {
            return error.rawValueLocalized
        }
        Debugger.printFailure("Failed to get localized raw value for \(String(describing: self))")
        return self.localizedDescription
    }
}

protocol RawValueLocalizable {
    var rawValue: String { get }
}

extension RawValueLocalizable {
    var rawValueLocalized: String {
        return self.rawValue.localized()
    }
}
