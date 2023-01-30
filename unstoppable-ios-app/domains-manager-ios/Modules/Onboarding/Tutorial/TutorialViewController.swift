//
//  TutorialViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 13.03.2022.
//

import UIKit

protocol TutorialViewControllerProtocol: UIViewController, CNavigationControllerChild {
    
}

final class TutorialViewController: UIPageViewController {

    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [
            self.newTutorialViewController(type: .tutorialScreen1),
            self.newTutorialViewController(type: .tutorialScreen2),
            self.newTutorialViewController(type: .tutorialScreen3)
        ]
    }()
    
    private var pageControl = UIPageControl()
    private var createNewWalletButton = MainButton()
    var presenter: TutorialViewPresenterProtocol!
    
    var navBackButtonConfiguration: CNavigationBarContentView.BackButtonConfiguration {
        .init(backArrowIcon: .navArrowLeft,
              tintColor: .foregroundDefault,
              backTitleVisible: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        setFirstTutorialScreen()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async { [weak self] in 
            self?.navigationItem.rightBarButtonItem?.customView?.semanticContentAttribute = .forceRightToLeft
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presenter.viewDidAppear()
        appContext.analyticsService.log(event: .viewDidAppear, withParameters: [.viewName: Analytics.ViewName.onboardingTutorial.rawValue])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let buttonSideOffset: CGFloat = 16
        let bottomOffset: CGFloat = 14 + view.safeAreaInsets.bottom
        createNewWalletButton.frame = CGRect(x: buttonSideOffset,
                                             y: view.bounds.height - MainButton.height - bottomOffset,
                                             width: view.bounds.width - (buttonSideOffset * 2),
                                             height: MainButton.height)
    }
}

// MARK: - TutorialViewControllerProtocol
extension TutorialViewController: TutorialViewControllerProtocol { }

// MARK: - UIPageViewControllerDelegate
extension TutorialViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        self.pageControl.currentPage = orderedViewControllers.firstIndex(of: pageContentViewController)!
        logTutorialSwipe()
    }
}

// MARK: - UIPageViewControllerDataSource
extension TutorialViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil // orderedViewControllers.last
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil // orderedViewControllers.first
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        orderedViewControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
            let firstViewControllerIndex = orderedViewControllers.firstIndex(of: firstViewController) else {
                return 0
        }
        
        return firstViewControllerIndex
    }
}

// MARK: - Actions
private extension TutorialViewController {
    @objc func didTapPageControl(_ pageControl: UIPageControl) {
        guard let firstViewController = viewControllers?.first,
              let firstViewControllerIndex = orderedViewControllers.firstIndex(of: firstViewController) else {
            return
        }
        
        let direction: UIPageViewController.NavigationDirection = pageControl.currentPage > firstViewControllerIndex ? .forward : .reverse
        setViewControllers([orderedViewControllers[pageControl.currentPage]], direction: direction, animated: true)
        logTutorialSwipe()
    }
    
    @objc func didPressCreateNewWalletButton(_ sender: UITapGestureRecognizer) {
        logButtonPressedAnalyticEvents(button: .getStarted)
        presenter?.didPressCreateNewWalletButton()
    }
    
    @objc func didPressBuyDomain(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .buyDomains)
        presenter?.didPressBuyDomain()
    }
}

// MARK: - Setup
private extension TutorialViewController {
    func setup() {
        setupView()
        setupDelegates()
        setupCreateNewWalletButton()
        configurePageControl()
        setupNavigationBar()
    }
    
    func setupView() {
        view.backgroundColor = .backgroundDefault
    }
    
    func setupDelegates() {
        self.dataSource = self
        self.delegate = self
    }
    
    func setupCreateNewWalletButton() {
        view.addSubview(createNewWalletButton)
        createNewWalletButton.accessibilityIdentifier = "Tutorial Create New Button"
        createNewWalletButton.setTitle(String.Constants.getStarted.localized(), image: nil)
        createNewWalletButton.addTarget(self, action: #selector(didPressCreateNewWalletButton(_:)), for: .touchUpInside)
    }
    
    func configurePageControl() {
        self.view.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        let distanceToNewWalletButton: CGFloat
        switch deviceSize {
        case .i4Inch:
            distanceToNewWalletButton = 8
        case .i4_7Inch:
            distanceToNewWalletButton = 22
        default:
            distanceToNewWalletButton = 32
        }
        createNewWalletButton.topAnchor.constraint(equalTo: pageControl.bottomAnchor,
                                                   constant: distanceToNewWalletButton).isActive = true
        pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        
        self.pageControl.numberOfPages = orderedViewControllers.count
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = .foregroundDefault
        self.pageControl.pageIndicatorTintColor = .foregroundSubtle
        self.pageControl.currentPageIndicatorTintColor = .foregroundDefault
        self.pageControl.addTarget(self, action: #selector(didTapPageControl), for: .valueChanged)
    }
    
    func setFirstTutorialScreen() {
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
    }
    
    func newTutorialViewController(type: TutorialScreenType) -> UIViewController {
        let vc = UIStoryboard(name: "Tutorial", bundle: nil)
            .instantiateViewController(withIdentifier: "TutorialScreen") as! TutorialStepViewController
        vc.loadViewIfNeeded()
        vc.configureWith(screenType: type)
        
        return vc
    }
    
    func setupNavigationBar() {
        let logoImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        logoImageView.image = #imageLiteral(resourceName: "unstoppableDomainsLogo")
        navigationItem.titleView = logoImageView
        
        /* Disabled 'Buy Domain' button
        let buyButton = LinkButton()
        buyButton.setTitle(String.Constants.buyDomain.localized(), image: nil)
        buyButton.semanticContentAttribute = .forceRightToLeft
        buyButton.addTarget(self, action: #selector(didPressBuyDomain), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buyButton)
         */
        customiseNavigationBackButton()
    }
    
    func logButtonPressedAnalyticEvents(button: Analytics.Button) {
        appContext.analyticsService.log(event: .buttonPressed, withParameters: [.button : button.rawValue,
                                                                            .viewName: Analytics.ViewName.onboardingTutorial.rawValue])
    }
    
    func logTutorialSwipe() {
        appContext.analyticsService.log(event: .didSwipeTutorialPage, withParameters: [.pageNum : String(pageControl.currentPage + 1),
                                                                                   .viewName: Analytics.ViewName.onboardingTutorial.rawValue])
    }
}

// MARK: - TutorialScreenType
extension TutorialViewController {
    enum TutorialScreenType {
        case tutorialScreen1
        case tutorialScreen2
        case tutorialScreen3
        
        var image: UIImage {
            switch self {
            case .tutorialScreen1: return #imageLiteral(resourceName: "tutorialIllustration1")
            case .tutorialScreen2: return #imageLiteral(resourceName: "tutorialIllustration2")
            case .tutorialScreen3: return #imageLiteral(resourceName: "tutorialIllustration3")
            }
        }
        
        var name: String {
            switch self {
            case .tutorialScreen1: return String.Constants.tutorialScreen1Name.localized()
            case .tutorialScreen2: return String.Constants.tutorialScreen2Name.localized()
            case .tutorialScreen3: return String.Constants.tutorialScreen3Name.localized()
            }
        }
        
        var description: String {
            switch self {
            case .tutorialScreen1: return String.Constants.tutorialScreen1Description.localized()
            case .tutorialScreen2: return String.Constants.tutorialScreen2Description.localized()
            case .tutorialScreen3: return String.Constants.tutorialScreen3Description.localized()
            }
        }
    }
}
