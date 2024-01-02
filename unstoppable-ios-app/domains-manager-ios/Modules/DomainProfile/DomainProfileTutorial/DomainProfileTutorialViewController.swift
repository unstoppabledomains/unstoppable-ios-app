//
//  DomainProfileTutorialViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2022.
//

import UIKit

final class DomainProfileTutorialViewController: BaseViewController {

    @IBOutlet private weak var pageViewControllerContainerView: UIView!
    @IBOutlet private weak var actionButton: UDConfigurableButton!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var actionButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentStackView: UIStackView!
    
    private var pageViewController: UIPageViewController!
    private lazy var tutorialItems: [TutorialItem] = useCase.tutorialItems
    private var numberOfPages: Int { tutorialItems.count }
    private lazy var currentTutorialItem: TutorialItem = {
        let index = pageControl.currentPage
        return tutorialItems[index]
    }()
    private lazy var currentVisibleItem: TutorialItem = {
        tutorialItems[0]
    }()
    override var analyticsName: Analytics.ViewName { .domainProfileTutorial }
    var useCase: UseCase = .largeTutorial
    var completionCallback: EmptyCallback?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) { [weak self] in
            completion?()
            self?.completionCallback?()
        }
    }
}

// MARK: - UIPageViewControllerDelegate
extension DomainProfileTutorialViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let viewController = pendingViewControllers.first else { return }
        
        pageControl.currentPage = getCurrentPage(viewController: viewController)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let viewController = pageViewController.viewControllers?.first else { return }
        pageControl.currentPage = getCurrentPage(viewController: viewController)
        currentTutorialItem = tutorialItems[pageControl.currentPage]
        if currentVisibleItem != currentTutorialItem {
            currentVisibleItem = currentTutorialItem
            logCurrentItemShownEvent()
            setupActionButton()
        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension DomainProfileTutorialViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentIndex = getCurrentPage(viewController: viewController)
        if currentIndex > 0 {
            let previousItem = tutorialItems[currentIndex - 1]
            return tutorialViewController(for: previousItem)
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let nextIndex = getCurrentPage(viewController: viewController) + 1
        if nextIndex < numberOfPages {
            let nextItem = tutorialItems[nextIndex]
            return tutorialViewController(for: nextItem)
        }
        return nil
    }
}

// MARK: - Actions
private extension DomainProfileTutorialViewController {
    @IBAction func actionButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .next)
        if !isLastItem {
            let nextItem = tutorialItems[pageControl.currentPage + 1]
            updateCurrentTutorialItem(nextItem, animated: true, direction: .forward)
            pageControl.currentPage += 1
            setupActionButton()
        } else {
            switch useCase {
            case .largeTutorial:
                dismiss(animated: true, completion: nil)
            case .pullUp, .pullUpPrivacyOnly:
                completionCallback?()
            }
        }
    }
    
    var isLastItem: Bool {
        let nextIndex = pageControl.currentPage + 1
        return nextIndex >= numberOfPages
    }
}

// MARK: - Setup methods
private extension DomainProfileTutorialViewController {
    func setup() {
        setupUI()
    }
    
    func setupUI() {
        setupPageControlVisibility()
        setupActionButton()
        setupPageControl()
        setupPageViewController()
        if deviceSize == .i4Inch {
            contentStackView.spacing = 24
        }
    }
    
    func setupPageControl() {
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .backgroundEmphasis
        pageControl.pageIndicatorTintColor = .backgroundMuted2
    }
    
    func setupPageControlVisibility() {
        pageControl.isHidden = tutorialItems.count <= 1
        pageViewControllerContainerView.isUserInteractionEnabled = !pageControl.isHidden
    }
    
    func setupPageViewController() {
        guard pageViewController == nil else { return }
        
        pageViewControllerContainerView.backgroundColor = .clear
        
        let options: [UIPageViewController.OptionsKey : Any] = [.interPageSpacing : 0]
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: options)
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        addChild(pageViewController)
        pageViewController.view.backgroundColor = UIColor.clear
        pageViewController.view.embedInSuperView(pageViewControllerContainerView)
        pageViewController.didMove(toParent: self)
        
        setFirstItem()
    }
    
    func setFirstItem() {
        updateCurrentTutorialItem(tutorialItems[pageControl.currentPage], animated: false, direction: .forward)
        logCurrentItemShownEvent()
    }
    
    func setupActionButton() {
        actionButton.imageLayout = .trailing

        switch useCase {
        case .largeTutorial, .pullUp:
            let title: String
            let image: UIImage? = isLastItem ? nil : .arrowRight

            if case.pullUp = useCase {
                if isLastItem {
                    title = String.Constants.gotIt.localized()
                    actionButton.setConfiguration(.largePrimaryButtonConfiguration)
                } else {
                    actionButton.setConfiguration(.largeGhostPrimaryButtonConfiguration)
                    title = String.Constants.next.localized()
                }
            } else {
                title = isLastItem ? String.Constants.getStarted.localized() : String.Constants.next.localized()
            }
            actionButton.setTitle(title, image: image)
        case .pullUpPrivacyOnly:
            actionButton.setConfiguration(.secondaryButtonConfiguration)
            actionButton.setTitle(String.Constants.gotIt.localized(), image: nil)
        }
        actionButtonTopConstraint.constant = useCase.actionButtonTopSpace
    }
    
    func tutorialViewController(for tutorialItem: TutorialItem) -> UIViewController {
        let viewController: UIViewController
        switch tutorialItem {
        case .web3Profile:
            let web3ViewController = DomainProfileTutorialItemWeb3ViewController()
            web3ViewController.style = useCase.web3Style
            viewController = web3ViewController
        case .privacy:
            let privacyViewController = DomainProfileTutorialItemPrivacyViewController()
            privacyViewController.style = useCase.privacyStyle
            viewController = privacyViewController
        }
        viewController.view.tag = tutorialItem.rawValue
        return viewController
    }
    
    func updateCurrentTutorialItem(_ tutorialItem: TutorialItem, animated: Bool, direction: UIPageViewController.NavigationDirection) {
        let viewController = tutorialViewController(for: tutorialItem)
        setButtonsEnabled(false)
        pageViewController.setViewControllers([viewController], direction: direction, animated: animated) { [weak self] _ in
            self?.setButtonsEnabled(true)
        }
    }
    
    func getCurrentPage(viewController: UIViewController) -> Int {
        viewController.view.tag
    }
    
    func setButtonsEnabled(_ isEnabled: Bool) {
        actionButton.isUserInteractionEnabled = isEnabled
    }
    
    func logCurrentItemShownEvent() {

    }
}

extension DomainProfileTutorialViewController {
    enum TutorialItem: Int, CaseIterable {
        case web3Profile
        case privacy
    }
    
    enum UseCase {
        case largeTutorial, pullUp, pullUpPrivacyOnly
        
        var tutorialItems: [TutorialItem] {
            switch self {
            case .largeTutorial, .pullUp:
                return [.web3Profile, .privacy]
            case .pullUpPrivacyOnly:
                return [.privacy]
            }
        }
        
        @MainActor
        var actionButtonTopSpace: CGFloat {
            switch self {
            case .largeTutorial:
                if deviceSize == .i4Inch {
                    return 14
                }
                return UIScreen.main.bounds.height > 890 ? 80 : 34
            case .pullUp:
                return 18
            case .pullUpPrivacyOnly:
                return 24
            }
        }
        
        var web3Style: DomainProfileTutorialItemWeb3ViewController.Style {
            switch self {
            case .largeTutorial:
                return .large
            case .pullUpPrivacyOnly, .pullUp:
                return .pullUp
            }
        }
        
        var privacyStyle: DomainProfileTutorialItemPrivacyViewController.Style {
            switch self {
            case .largeTutorial:
                return .large
            case .pullUp:
                return .pullUp
            case .pullUpPrivacyOnly:
                return .pullUpSingle
            }
        }
    }
}
