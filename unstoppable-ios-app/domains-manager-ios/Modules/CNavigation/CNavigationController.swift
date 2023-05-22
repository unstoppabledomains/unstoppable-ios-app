//
//  CNavigationController.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 24.07.2022.
//

import UIKit

protocol CNavigationControllerDelegate: AnyObject {
    func navigationController(_ navigationController: CNavigationController, willShow viewController: UIViewController, animated: Bool)
    func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool)
}

extension CNavigationControllerDelegate {
    func navigationController(_ navigationController: CNavigationController, willShow viewController: UIViewController, animated: Bool) { }
    func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool) { }
}

class CNavigationController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle { topVisibleViewController().preferredStatusBarStyle  }
    private(set) var navigationBar: CNavigationBar!
    private var viewControllersContainerView: UIView!
    private(set) var transitionHandler: CNavigationTransitionHandler!
    private var animationDuration: TimeInterval { CNavigationHelper.DefaultNavAnimationDuration }
    private(set) var isTransitioning = false
    private let navigationBarScrollingController = CNavigationBarScrollingController()
    weak var delegate: CNavigationControllerDelegate?
    var backButtonPressedCallback: (()->())?
    var rootViewController: UIViewController?
    var viewControllers = [UIViewController]()
    var topViewController: UIViewController? { viewControllers.last }
    var canMoveBack: Bool { (topViewController as? CNavigationControllerChild)?.shouldPopOnBackButton() ?? true }

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(rootViewController: UIViewController) {
        self.init()
        self.rootViewController = rootViewController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        if let rootViewController = self.rootViewController {
            pushViewController(rootViewController, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        topViewController?.loadViewIfNeeded()
        if self.rootViewController == nil {
            if let rootViewController = self.viewControllers.first {
                self.rootViewController = rootViewController
                viewControllers.forEach { vc in
                    vc.loadViewIfNeeded()
                    vc.willMove(toParent: self)
                    vc.view.frame = self.viewControllersContainerView.bounds
                    self.viewControllersContainerView.addSubview(vc.view)
                    self.addChild(vc)
                    vc.didMove(toParent: self)
                }
                updateNavigationBarAfterNavigation()
            } else {
                fatalError("Root view controller is not set")                
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateFrames()
    }
    
}

// MARK: - Navigation
extension CNavigationController {
    @objc open func pushViewController(_ viewController: UIViewController, animated: Bool) {
        guard !isTransitioning else { return }
        
        pushAnimate(viewController, animated: animated) { [weak self] in
            self?.viewControllers.append(viewController)
        }
    }
    
    public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        guard !isTransitioning else { return }
        guard !viewControllers.isEmpty else {
            fatalError("Root view controller is not set")
        }
        
        let currentControllers = self.viewControllers
        pushAnimate(viewControllers.last!, animated: animated) { [weak self] in
            guard let self = self else { return }
            
            viewControllers.forEach { vc in
                vc.loadViewIfNeeded()
                vc.willMove(toParent: self)
                vc.view.frame = self.viewControllersContainerView.bounds
                self.viewControllersContainerView.addSubview(vc.view)
                self.addChild(vc)
            }
            self.viewControllers = viewControllers
            self.rootViewController = viewControllers.first
            
            currentControllers.forEach { vc in
                vc.didMove(toParent: nil)
                vc.view.removeFromSuperview()
            }
        }
    }
    
    @discardableResult
    @objc open func popViewController(animated: Bool, completion: (()->())? = nil) -> UIViewController?  {
        guard canMoveBack else { return nil }
        guard viewControllers.count > 1 else {
            return nil
        }
        
        let toViewController = viewControllers[viewControllers.count - 2]
        
        return popToViewController(toViewController, animated: true, completion: completion)?.first
    }
    
    @discardableResult
    public func popToViewController(_ viewController: UIViewController, animated: Bool, completion: (()->())? = nil) -> [UIViewController]? {
        guard !isTransitioning else { return nil }
        guard let fromViewController = self.topViewController,
              fromViewController != viewController else {
            return nil
        }
        
        if let i = viewControllers.firstIndex(of: viewController) {
            let toViewController = viewControllers[i]
            let leftViewControllers = viewControllers.prefix(i + 1)
            let droppedViewControllers = Array(viewControllers.suffix(viewControllers.count - leftViewControllers.count))
            for viewController in droppedViewControllers {
                (viewController as? CNavigationControllerChildNavigationHandler)?.cNavigationChildWillBeDismissed()
            }
            popAnimate(fromViewController: fromViewController, toViewController: toViewController, animated: animated) { [weak self] in
                self?.viewControllers = Array(leftViewControllers)
                self?.willRemove(viewControllers: droppedViewControllers)
                droppedViewControllers.forEach { vc in
                    (vc as? CNavigationControllerChildNavigationHandler)?.cNavigationChildDidDismissed()
                    vc.didMove(toParent: nil)
                    vc.view.removeFromSuperview()
                }
                DispatchQueue.main.async {
                    completion?()
                }
            }
            
            return droppedViewControllers
        }
        
        return nil
    }
    
    @discardableResult
    func popTo<T: UIViewController>(_ viewControllerType: T.Type, completion: (()->())? = nil) -> UIViewController? {
        for vc in viewControllers where vc is T {
            return self.popToViewController(vc, animated: true, completion: completion)?.last
        }
        return nil
    }
    
    @discardableResult
    public func popToRootViewController(animated: Bool, completion: (()->())? = nil) -> [UIViewController]? {
        guard viewControllers.count > 1 else { return nil }
        
        let toViewController = viewControllers.first!
        
        return popToViewController(toViewController, animated: true, completion: completion)
    }
}

// MARK: - Open methods
extension CNavigationController {
    func underlyingScrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isTransitioning,
              let topViewController,
              let scrollingViewController = CNavigationHelper.findViewController(of: scrollView) else { return }
        guard topViewController == scrollingViewController || topViewController.allChilds().contains(scrollingViewController) else { return }
        
        updateNavBarScrollingState(in: scrollView)
    }
    
    func underlyingScrollViewDidFinishScroll(_ scrollView: UIScrollView) {
        guard CNavigationHelper.findViewController(of: scrollView) == topViewController else { return }
        
        navigationBarScrollingController.handleScrollingFinished(of: scrollView, in: navigationBar)
    }
    
    func updateNavigationBar() {
        guard let topViewController = self.topViewController else { return }
        
        let navChild = topViewController as? CNavigationControllerChild
        
        UIView.performWithoutAnimation {
            navigationBar.setupWith(child: navChild, navigationItem: topViewController.navigationItem)
            if let scrollView = CNavigationHelper.topScrollableView(in: topViewController.view) {
                updateNavBarScrollingState(in: scrollView)
            }
            navigationBar.isHidden = navChild?.isNavBarHidden ?? false || topViewController is CNavigationController
            navigationBar.setBackButton(hidden: viewControllers.count <= 1 && !navigationBar.alwaysShowBackButton)
        }
    }
    
    @objc func willRemove(viewControllers: [UIViewController]) { }
    
    func updateStatusBar() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            UIView.animate(withDuration: 0.3) {
                self?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

// MARK: - Private methods
private extension CNavigationController {
    func backButtonPressed() {
        guard popViewController(animated: true) != nil else { return }
        
        backButtonPressedCallback?()
    }
    
    func setTransitioning(_ isTransitioning: Bool) {
        self.isTransitioning = isTransitioning
        if !isTransitioning {
            transitionHandler.navigationControllerDidFinishNavigation(self)
            updateStatusBar()
        }
    }
    
    func updateNavigationBarAfterNavigation() {
        updateNavigationBar()
        navigationBar.frame.origin = .zero
    }
    
    func updateNavBarScrollingState(in scrollView: UIScrollView) {
        if let customBehaviour = (topViewController as? CNavigationControllerChild)?.customScrollingBehaviour(yOffset: CNavigationHelper.contentYOffset(of: scrollView),
                                                                                                              in: navigationBar) {
            customBehaviour()
        } else {
            navigationBarScrollingController.handleScrolling(of: scrollView, in: navigationBar)
        }
    }
}

// MARK: - Push / Pop animations
private extension CNavigationController {
    func pushAnimate(_ viewController: UIViewController, animated: Bool, completion: (()->())? = nil) {
        setTransitioning(true)
        
        let containerView = self.viewControllersContainerView!
        viewController.willMove(toParent: self)
        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = true
        viewController.view.frame = containerView.bounds
        topViewController?.beginAppearanceTransition(false, animated: animated)
        viewController.beginAppearanceTransition(true, animated: animated)
        containerView.addSubview(viewController.view)
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
        delegate?.navigationController(self, willShow: viewController, animated: animated)
        
        func finishPush() {
            viewController.didMove(toParent: self)
            completion?()
            updateNavigationBarAfterNavigation()
            setTransitioning(false)
        }
        
        if animated,
           let topViewController = self.topViewController,
           topViewController != viewController {
            let transition = self.transitionHandler.navigationController(self,
                                                                         animationControllerFor: .push,
                                                                         from: topViewController,
                                                                         to: viewController) ?? CNavigationControllerDefaultPushAnimation(animationDuration: self.animationDuration)
            let context = NavigationTransitioningContext(containerView: containerView,
                                                         isAnimated: animated,
                                                         fromViewController: topViewController,
                                                         toViewController: viewController,
                                                         with: transition)
            
            let navTransition = self.transitionHandler.navigationController(self,
                                                                            navBarAnimationControllerFor: .push,
                                                                            from: topViewController,
                                                                            to: viewController) ?? CNavigationControllerDefaultNavigationBarPushAnimation(animationDuration: self.animationDuration)
            
            if let animator = transition.interruptibleAnimator?(using: context) {
                context.set(navigationAnimator: navTransition.interruptibleAnimator!(using: context))
                context.set(animator: animator)
            }
            
            func finishTransition() {
                transition.animationEnded?(true)
                topViewController.endAppearanceTransition()
                finishPush()
                self.navigationBar.setBackButton(hidden: false)
                viewController.endAppearanceTransition()
                self.delegate?.navigationController(self, didShow: viewController, animated: animated)
            }
            
            func cancelTransition() {
                viewController.beginAppearanceTransition(false, animated: animated)
                viewController.view.removeFromSuperview()
                viewController.endAppearanceTransition()
                viewController.didMove(toParent: nil)
                
                topViewController.beginAppearanceTransition(true, animated: animated)
                topViewController.endAppearanceTransition()
                
                self.setTransitioning(false)
            }
            
            if let interactive = self.transitionHandler.navigationController(self,
                                                                             interactionControllerFor: transition) {
                interactive.startInteractiveTransition(context)
            } else {
                transition.animateTransition(using: context)
                navTransition.animateTransition(using: context)
            }
            
            context.completedCallback = { isCompleted in
                if isCompleted {
                    finishTransition()
                } else {
                    cancelTransition()
                }
            }
        } else {
            finishPush()
        }
    }
    
    func popAnimate(fromViewController: UIViewController, toViewController: UIViewController, animated: Bool, completion: @escaping ()->()) {
        setTransitioning(true)
        let containerView = self.viewControllersContainerView!
        fromViewController.willMove(toParent: nil)
        fromViewController.beginAppearanceTransition(false, animated: animated)
        toViewController.beginAppearanceTransition(true, animated: animated)
        delegate?.navigationController(self, willShow: toViewController, animated: animated)

        let transition = transitionHandler.navigationController(self,
                                                        animationControllerFor: .pop,
                                                        from: fromViewController,
                                                        to: toViewController) ?? CNavigationControllerDefaultPopAnimation(animationDuration: animationDuration)
        let context = NavigationTransitioningContext(containerView: containerView,
                                                     isAnimated: animated,
                                                     fromViewController: fromViewController,
                                                     toViewController: toViewController,
                                                     with: transition)
        if let animator = transition.interruptibleAnimator?(using: context) {
            context.set(animator: animator)
        }
        let navTransition = transitionHandler.navigationController(self,
                                                                   navBarAnimationControllerFor: .pop,
                                                                   from: fromViewController,
                                                                   to: toViewController) ?? CNavigationControllerDefaultNavigationBarPopAnimation(animationDuration: animationDuration)
        
        context.set(navigationAnimator: navTransition.interruptibleAnimator!(using: context))
        
        func finishTransition() {
            transition.animationEnded?(true)
            fromViewController.view.removeFromSuperview()
            fromViewController.endAppearanceTransition()
            fromViewController.removeFromParent()
            completion()
            toViewController.endAppearanceTransition()
            delegate?.navigationController(self, didShow: toViewController, animated: animated)

            if viewControllers.count == 1 {
                navigationBar.setBackButton(hidden: true)
            }
            updateNavigationBarAfterNavigation()
            setTransitioning(false)
        }
        
        func cancelTransition() {
            toViewController.beginAppearanceTransition(false, animated: animated)
            toViewController.endAppearanceTransition()

            fromViewController.beginAppearanceTransition(true, animated: animated)
            fromViewController.endAppearanceTransition()
            fromViewController.didMove(toParent: self)
            
            setTransitioning(false)
        }
        var isSwipe = false
        
        if let interactive = transitionHandler.navigationController(self,
                                                            interactionControllerFor: transition) {
            interactive.startInteractiveTransition(context)
            isSwipe = true
        } else {
            transition.animateTransition(using: context)
            navTransition.animateTransition(using: context)
        }
        context.completedCallback = { isCompleted in
            if isCompleted {
                if isSwipe,
                   let vc = fromViewController as? BaseViewController {
                    appContext.analyticsService.log(event: .didSwipeNavigationBack,
                                                withParameters: [.viewName: vc.analyticsName.rawValue])
                }
                finishTransition()
            } else {
                cancelTransition()
            }
        }
    }
}

// MARK: - Setup methods
private extension CNavigationController {
    func setup() {
        setupControllersContainerView()
        setupNavigationBarView()
        addSwipeGestures()
        updateFrames()
    }
    
    func setupNavigationBarView() {
        navigationBar = CNavigationBar()
        navigationBar.backButtonPressedCallback = { [weak self] in
            self?.backButtonPressed()
        }
        navigationBar.translatesAutoresizingMaskIntoConstraints = true
        navigationBar.backgroundColor = .clear
        navigationBar.frame.size.width = view.bounds.width
        view.addSubview(navigationBar)
        navigationBar.setNeedsLayout()
        navigationBar.layoutIfNeeded()
        
        if presentingViewController != nil,
           modalPresentationStyle == .pageSheet {
            navigationBar.isModalInPageSheet = true
        }
    }
    
    func setupControllersContainerView() {
        viewControllersContainerView = UIView()
        viewControllersContainerView.translatesAutoresizingMaskIntoConstraints = true
        viewControllersContainerView.backgroundColor = .clear
        view.addSubview(viewControllersContainerView)
    }
    
    func addSwipeGestures() {
        transitionHandler = CNavigationTransitionHandler(view: view, navigationController: self, animationDuration: animationDuration)
    }
    
    func updateFrames() {
        viewControllersContainerView.frame = view.bounds
    }
}

extension UIViewController {
    var cNavigationController: CNavigationController? { parent as? CNavigationController }
    var cNavigationBar: CNavigationBar? { cNavigationController?.navigationBar }
}

extension CNavigationController {
    func setViewControllerWithEmptyRoot(_ viewController: UIViewController) {
        let emptyVC = BaseViewController()
        setViewControllers([emptyVC, viewController], animated: false)
        emptyVC.loadViewIfNeeded()
    }
}
