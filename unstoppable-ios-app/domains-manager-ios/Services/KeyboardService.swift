//
//  KeyboardService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit
import GameController
import Combine

@MainActor
protocol KeyboardServiceListener: AnyObject {
    func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat)
    func keyboardDidAdjustFrame(keyboardHeight: CGFloat)
    func keyboardDidShowAction()
    func keyboardWillHideAction(duration: Double, curve: Int)
}

final class KeyboardServiceListenerHolder: Equatable {
    
    weak var listener: KeyboardServiceListener?
    
    init(listener: KeyboardServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: KeyboardServiceListenerHolder, rhs: KeyboardServiceListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}

@MainActor
final class KeyboardService {
    
    static let shared = KeyboardService()
    
    @Published
    private(set) var keyboardFrame: CGRect = .zero
    var keyboardFramePublisher: Published<CGRect>.Publisher { $keyboardFrame }
    private(set) var keyboardAnimationDuration: TimeInterval = 0.25
    private(set) var keyboardAppeared = false
    private(set) var isKeyboardOpened = false
    private var cancellables: Set<AnyCancellable> = []
    private var listeners: [KeyboardServiceListenerHolder] = []
    
    private init() {
        setup()
    }
    
}

// MARK: - Open methods
extension KeyboardService {
    var isExternalKeyboard: Bool {
        guard GCKeyboard.coalesced != nil else { return false }
        
        return keyboardFrame.height < 100
    }
    
    func isButtonPressedFor(key: GCKeyCode) -> Bool {
        guard let keyboardInput = GCKeyboard.coalesced?.keyboardInput else { return false }
        
        return keyboardInput.button(forKeyCode: key)?.isPressed == true
    }
    
    func hideKeyboard() {
        appContext.coreAppCoordinator.topVC?.view.endEditing(true)
    }
    
    func addListener(_ listener: KeyboardServiceListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: KeyboardServiceListener) {
        listeners.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - Private methods
private extension KeyboardService {
    func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        _ = isExternalKeyboard
        
        listeners.forEach { holder in
            holder.listener?.keyboardWillShowAction(duration: duration, curve: curve, keyboardHeight: keyboardHeight)
        }
    }
    
    func keyboardDidShowAction() {
        listeners.forEach { holder in
            holder.listener?.keyboardDidShowAction()
        }
    }
    
    func keyboardWillHideAction(duration: Double, curve: Int) {
        listeners.forEach { holder in
            holder.listener?.keyboardWillHideAction(duration: duration, curve: curve)
        }
    }
    
    func keyboardDidAdjustFrameAction(keyboardHeight: CGFloat) {
        listeners.forEach { holder in
            holder.listener?.keyboardDidAdjustFrame(keyboardHeight: keyboardHeight)
        }
    }
}

// MARK: - Setup methods
private extension KeyboardService {
    func setup() {
        addKeyboardObservers()
    }
    
    func addKeyboardObservers() {
        guard cancellables.isEmpty else { return }
        
        observeKeyboardNotification(UIResponder.keyboardDidShowNotification) { [weak self] _ in
            self?.keyboardDidShowAction()
        }
        observeKeyboardNotification(UIResponder.keyboardWillShowNotification) { [weak self] notification in
            self?.keyboardWillShow(notification: notification)
        }
        observeKeyboardNotification(UIResponder.keyboardWillHideNotification) { [weak self] notification in
            self?.keyboardWillHide(notification: notification)
        }
    }
    
    func observeKeyboardNotification(_ name: Notification.Name, action: @escaping (Notification) -> Void) {
        NotificationCenter.Publisher(center: NotificationCenter.default, name: name, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { notification in action(notification) }
            .store(in: &cancellables)
    }
    
    func keyboardWillShow(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            guard keyboardFrame.cgRectValue != self.keyboardFrame else { return }
            
            self.keyboardFrame = keyboardFrame.cgRectValue
            self.keyboardDidAdjustFrameAction(keyboardHeight: self.keyboardFrame.height)
            if isKeyboardOpened {
                return
            }
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
    }
    
    func keyboardWillHide(notification: Notification) {
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
    }
}
