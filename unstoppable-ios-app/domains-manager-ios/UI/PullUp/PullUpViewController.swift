//
//  PullUpViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.04.2022.
//

import UIKit

final class PullUpViewController: UIViewController {
    
    private var pullUpView: PullUpView!
    private var blurView: UIView?
    private var isPresentedAsPageSheet: Bool { modalPresentationStyle == .pageSheet }
    private var didCloseCallback: EmptyCallback?
    private(set) var pullUp: Analytics.PullUp = .unspecified
    private var additionalAnalyticParameters: Analytics.EventParameters = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    convenience init(pullUp: Analytics.PullUp,
                     additionalAnalyticParameters: Analytics.EventParameters,
                     height: CGFloat?,
                     subview: UIView,
                     isDismissAble: Bool = true,
                     backgroundColor: UIColor = .systemBackground,
                     didCloseCallback: EmptyCallback?) {
        self.init()
        
        self.pullUp = pullUp
        self.additionalAnalyticParameters = additionalAnalyticParameters
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .overFullScreen
        
        self.view = UIView(frame: UIScreen.main.bounds)
        
        self.pullUpView = PullUpView(superView: view,
                                     height: height ?? UIScreen.main.bounds.height,
                                     isDismissAble: isDismissAble,
                                     subview: subview)
        self.pullUpView.panGesture?.isEnabled = height != nil
        self.pullUpView.setDragIndicatorHidden(height == nil)
        self.pullUpView.containerView.backgroundColor = backgroundColor
        
        if height == nil {
            let navIcon: BaseViewController.NavBackIconStyle = isPresentedAsPageSheet ? .cancel : .arrow
            pullUpView.showNavButton(image: navIcon.icon,
                                     at: isPresentedAsPageSheet ? 76 : 58)
        }
        self.pullUpView.didCancelView = { [weak self] in
            self?.dismiss(animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presentationController?.delegate = self
        if !isPresentedAsPageSheet {
            setupBlurBackground()
        }
        self.view.addSubview(pullUpView)
        pullUpView.showUp()
        log(event: .pullUpDidAppear)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        log(event: .pullUpClosed)
        if isPresentedAsPageSheet {
            dismiss(completion: completion, isCancelled: pullUpView.isClosingDown, animated: true)
            return
        }
        
        if pullUpView.isClosingDown {
            hideBlurView { [weak self] in
                self?.dismiss(completion: completion, isCancelled: true)
            }
        } else {
            hideBlurView()
            pullUpView.closeDown { [weak self] in
                self?.dismiss(completion: completion, isCancelled: false)
            }
        }
    }
    
    private func dismiss(completion: (() -> Void)?, isCancelled: Bool, animated: Bool = false) {
        super.dismiss(animated: animated, completion: completion)
        
        if isCancelled {
            didCloseCallback?()
            didCloseCallback = nil
        }
    }
}

// MARK: - Open methods
extension PullUpViewController {
    func replaceContentWith(_ newSubview: UIView, newHeight: CGFloat,
                            pullUp: Analytics.PullUp, animated: Bool, didCloseCallback: EmptyCallback?) {
        log(event: .pullUpClosed)
        self.didCloseCallback?()
        self.pullUp = pullUp
        pullUpView.replaceContentWith(newSubview, newHeight: newHeight, animated: animated)
        log(event: .pullUpDidAppear)
        self.didCloseCallback = didCloseCallback
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension PullUpViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        log(event: .pullUpClosed)
        didCloseCallback?()
    }
}

// MARK: - Setup methods
private extension PullUpViewController {
    func setup() {
        view.backgroundColor = .clear
    }
    
    func setupBlurBackground() {
        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.backgroundColor = .backgroundEmphasisOpacity
        backgroundView.alpha = 0
        self.blurView = backgroundView
        view.addSubview(backgroundView)
        showBlurView()
    }
    
    func showBlurView(completion: EmptyCallback? = nil) {
        setBlurView(alpha: 1, completion: completion)
    }
    
    func hideBlurView(completion: EmptyCallback? = nil) {
        setBlurView(alpha: 0, completion: completion)
    }
    
    func setBlurView(alpha: CGFloat, completion: EmptyCallback?) {
        UIView.animate(withDuration: pullUpView.pullUpAnimationDuration) {
            self.blurView?.alpha = alpha
        } completion: { _ in
            completion?()
        }
    }
    
    func log(event: Analytics.Event) {
        if pullUp == .unspecified {
            Debugger.printFailure("Did not specify pull up name", critical: true)
        }
        appContext.analyticsService.log(event: event, withParameters: [.pullUpName: pullUp.rawValue].adding(additionalAnalyticParameters))
    }
}
