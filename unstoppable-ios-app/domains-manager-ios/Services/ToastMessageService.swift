//
//  ToastMessageService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.05.2022.
//

import UIKit

@MainActor
protocol ToastMessageServiceProtocol {
    func showToast(_ toast: Toast, isSticky: Bool)
    func removeStickyToast(_ toast: Toast)
    func showToast(_ toast: Toast,
                   in view: UIView,
                   at position: Toast.Position?,
                   isSticky: Bool,
                   dismissDelay: TimeInterval?,
                   action: EmptyCallback?)
    func removeToast(from view: UIView)
}

@MainActor
final class ToastMessageService {
        
    private let animationDuration: TimeInterval = 0.25
    private let dismissDelay: TimeInterval = 3 // sec
    private var visibleToast: ToastView?
    private var dismissToastWorkingItem: DispatchWorkItem?
    private var stickyToastView: ToastView?
    private var toastActions: [Toast : EmptyCallback] = [:]
    
    nonisolated init() { }
    
}

// MARK: - Open methods
extension ToastMessageService: ToastMessageServiceProtocol {
    func showToast(_ toast: Toast, isSticky: Bool) {
        if let visibleToast = self.visibleToast {
            if isSticky,
               stickyToastView?.toast == toast {
                // We already showing this sticky toast
                return
            }
            if visibleToast.toast == toast {
                dismissToastWorkingItem?.cancel()
                scheduleDismissWorkingItemFor(toastView: visibleToast, dismissDelay: dismissDelay)
                return
            } else {
                dismissToastWorkingItem?.perform()
            }
        }
        
        if isSticky,
           let stickyToastView = self.stickyToastView {
            removeToastView(stickyToastView)
        }
        
        let toastView = buildToastViewWith(message: toast.message,
                                           image: toast.image,
                                           secondaryMessage: toast.secondaryMessage,
                                           style: toast.style,
                                           in: nil)
        toastView.toast = toast
        toastView.isSticky = isSticky
        visibleToast = toastView
        showToastView(toastView, in: nil, at: .bottom, dismissDelay: dismissDelay)
    }
    
    func removeStickyToast(_ toast: Toast) {
        guard let stickyToastView = stickyToastView,
              stickyToastView.toast == toast else { return }
        
        removeAction(for: stickyToastView)
        removeToastView(stickyToastView)
        self.stickyToastView = stickyToastView
    }
    
    func showToast(_ toast: Toast,
                   in view: UIView,
                   at position: Toast.Position?,
                   isSticky: Bool,
                   dismissDelay: TimeInterval?,
                   action: EmptyCallback?) {
        if let toastView = view.firstSubviewOfType(ToastView.self) {
            if toastView.toast == toast {
                return
            }
            toastView.removeFromSuperview()
        }
        dismissToastWorkingItem?.perform()
        let toastView = buildToastViewWith(message: toast.message,
                                           image: toast.image,
                                           secondaryMessage: toast.secondaryMessage,
                                           style: toast.style,
                                           in: view.bounds)
        toastView.toast = toast
        toastView.isSticky = isSticky
        add(action: action, for: toast, to: toastView)
        visibleToast = toastView
        showToastView(toastView,
                      in: view,
                      at: position ?? .bottom,
                      dismissDelay: dismissDelay ?? self.dismissDelay)
    }
    
    func removeToast(from view: UIView) {
        if let toastView = view.firstSubviewOfType(ToastView.self) {
            removeAction(for: toastView)
            toastView.removeFromSuperview()
        }
    }
}

// MARK: - Private methods
private extension ToastMessageService {
    var window: UIWindow? { SceneDelegate.shared?.window }
    
    func buildToastViewWith(message: String,
                            image: UIImage,
                            secondaryMessage: String?,
                            style: Toast.Style,
                            in frame: CGRect?) -> ToastView {
        let windowFrame = frame ?? window?.frame ?? .zero
        let sideOffset: CGFloat = 12
        let view = ToastView(frame: CGRect(x: 0, y: 0, width: windowFrame.width, height: 36))
        view.backgroundColor = style.color
        view.layer.cornerRadius = 18
        
        let imageView = KeepingAnimationImageView(frame: CGRect(x: sideOffset, y: 10, width: 16, height: 16))
        imageView.image = image
        imageView.tintColor = style.tintColor
        view.addSubview(imageView)
        
        let labelFont: UIFont = .currentFont(withSize: 14, weight: .medium)
        let labelWidth = message.width(withConstrainedHeight: 20, font: labelFont)
        let label = UILabel(frame: CGRect(x: 36, y: 8, width: labelWidth, height: 20))
        label.setAttributedTextWith(text: message,
                                    font: labelFont,
                                    textColor: .foregroundOnEmphasis)
        view.addSubview(label)

        if let secondaryMessage = secondaryMessage {
            let secondaryLabelWidth = secondaryMessage.width(withConstrainedHeight: 20, font: labelFont)
            let secondaryLabel = UILabel(frame: CGRect(x: label.frame.maxX + 8,
                                                       y: label.frame.minY,
                                                       width: secondaryLabelWidth,
                                                       height: label.frame.height))
            secondaryLabel.setAttributedTextWith(text: secondaryMessage,
                                                 font: labelFont,
                                                 textColor: .foregroundOnEmphasisOpacity)
            
            view.addSubview(secondaryLabel)
            view.frame.size.width = secondaryLabel.frame.maxX + sideOffset
        } else {
            view.frame.size.width = label.frame.maxX + sideOffset
        }
        
        view.frame.origin.x = windowFrame.midX - (view.frame.width / 2)
        
        return view
    }
    
    func showToastView(_ toastView: ToastView, in view: UIView?, at position: Toast.Position, dismissDelay: TimeInterval) {
        guard let container = view ?? self.window else { return }
        
        if toastView.isSticky == false {
            addSwipeDismissGesture(to: toastView, at: position)
        } else {
            stickyToastView = toastView
        }
        
        // Set initial position
        let initialY: CGFloat
        switch position {
        case .bottom:
            initialY = container.bounds.height
        case .center:
            initialY = container.bounds.height / 2 - toastView.bounds.height / 2
        }
        toastView.initialY = initialY
        
        container.addSubview(toastView)
        
        // Set target position
        let targetY: CGFloat
        switch position {
        case .bottom:
            targetY = container.bounds.height - toastView.bounds.height - 48
        case .center:
            targetY = initialY
        }
        
        UIView.animate(withDuration: animationDuration) {
            toastView.targetY = targetY
        }
        
        if toastView.isSticky == false {
            scheduleDismissWorkingItemFor(toastView: toastView, dismissDelay: dismissDelay)
        }
    }
    
    func scheduleDismissWorkingItemFor(toastView: ToastView, dismissDelay: TimeInterval) {
        let dismissToastWorkingItem = DispatchWorkItem { [weak self, weak toastView] in
            if let toastView = toastView {
                self?.removeToastView(toastView)
            }
        }
        self.dismissToastWorkingItem = dismissToastWorkingItem
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay, execute: dismissToastWorkingItem)
    }
    
    func removeToastView(_ toastView: ToastView) {
        self.visibleToast = nil
        dismissToastWorkingItem?.cancel()
        dismissToastWorkingItem = nil
        
        UIView.animate(withDuration: animationDuration) {
            toastView.frame.origin.y = toastView.initialY
        } completion: { _ in
            toastView.removeFromSuperview()
        }
    }
    
    func addSwipeDismissGesture(to toastView: UIView, at position: Toast.Position) {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeDismissView))
        
        switch position {
        case .bottom, .center:
            swipeGesture.direction = .down
        }
        
        toastView.isUserInteractionEnabled = true
        toastView.addGestureRecognizer(swipeGesture)
    }
    
    @objc func swipeDismissView(_ gesture: UISwipeGestureRecognizer) {
        guard let toastView = gesture.view as? ToastView else { return }
        
        removeToastView(toastView)
    }
    
    func add(action: EmptyCallback?, for toast: Toast, to view: ToastView) {
        guard let action else { return }
        
        toastActions[toast] = action
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapToast)))
    }
    
    func removeAction(for toastView: ToastView) {
        if let toast = toastView.toast {
            toastActions[toast] = nil
        }
    }
    
    @objc func didTapToast(_ gesture: UITapGestureRecognizer) {
        guard let toastView = gesture.view as? ToastView,
            let toast = toastView.toast else { return }
        
        UDVibration.buttonTap.vibrate()
        let action = toastActions[toast]
        action?()
    }
}

final class ToastView: UIView {
    
    var toast: Toast?
    var initialY: CGFloat = 0 { didSet { frame.origin.y = initialY } }
    var targetY: CGFloat = 0 { didSet { frame.origin.y = targetY } }
    var isSticky = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        prepareToDisplay()
        applyFigmaShadow(style: .medium)
    }
    
    @objc private func prepareToDisplay() {
        switch toast {
        case .updatingRecords:
            let imageView = firstSubviewOfType(UIImageView.self)
            imageView?.runUpdatingRecordsAnimation()
        default:
            return
        }
    }
        
}
