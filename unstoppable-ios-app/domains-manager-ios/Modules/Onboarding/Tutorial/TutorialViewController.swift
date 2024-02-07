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
    
    private var createNewWalletButton = MainButton()
    private var progressView = DashesProgressView()
    private var currentPage = 0
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
        currentPage = orderedViewControllers.firstIndex(of: pageContentViewController)!
        let progress = (Double(currentPage) + 0.5) / Double(orderedViewControllers.count)
        UIView.animate(withDuration: 0.25) {
            self.progressView.setProgress(progress)
        }
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
        setupNavigationBar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupNavProgressView()
            self.setupWelcomeMessage()
        }
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
    
    func setFirstTutorialScreen() {
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
    }
    
    func setupWelcomeMessage() {
        guard deviceSize != .i4_7Inch,
              let navBar = cNavigationBar else { return }

        let imageViewContainer = UIView()
        imageViewContainer.translatesAutoresizingMaskIntoConstraints = false
        imageViewContainer.backgroundColor = .foregroundAccent
        imageViewContainer.layer.cornerRadius = 6
        
        let imageView = UIImageView(image: UIImage(named: "udLogo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageViewContainer.addSubview(imageView)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setAttributedTextWith(text: "Welcome to Unstoppable",
                                    font: .currentFont(withSize: 16, weight: .semibold),
                                    textColor: .foregroundDefault)
        
        let stack = UIStackView(arrangedSubviews: [imageViewContainer, label])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 8
        stack.alignment = .center
        
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([imageViewContainer.widthAnchor.constraint(equalToConstant: 24),
                                     imageViewContainer.widthAnchor.constraint(equalTo: imageViewContainer.heightAnchor),
                                     imageView.widthAnchor.constraint(equalToConstant: 18),
                                     imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
                                     imageView.centerXAnchor.constraint(equalTo: imageViewContainer.centerXAnchor),
                                     imageView.centerYAnchor.constraint(equalTo: imageViewContainer.centerYAnchor),
                                     stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     stack.topAnchor.constraint(equalTo: view.topAnchor, constant: navBar.bounds.height + 4)])
    }
    
    func newTutorialViewController(type: TutorialScreenType) -> UIViewController {
        let vc = UIStoryboard(name: "Tutorial", bundle: nil)
            .instantiateViewController(withIdentifier: "TutorialScreen") as! TutorialStepViewController
        vc.loadViewIfNeeded()
        vc.configureWith(screenType: type)
        
        return vc
    }
    
    func setupNavigationBar() {
        let offset: CGFloat = 16
        progressView.frame = CGRect(x: offset, y: 60, width: UIScreen.main.bounds.width - (offset * 2), height: 4)
        progressView.setWith(configuration: .white(numberOfDashes: 3))
        customiseNavigationBackButton()
    }
    
    func setupNavProgressView() {
        guard let navBar = cNavigationBar else { return }
        
        progressView.frame.origin.y = navBar.bounds.height - (navBar.navBarContentView.bounds.height / 2) - (progressView.frame.height / 2)
        progressView.setProgress(0.1666)
        view?.addSubview(progressView)
    }
    
    func logButtonPressedAnalyticEvents(button: Analytics.Button) {
        appContext.analyticsService.log(event: .buttonPressed, withParameters: [.button : button.rawValue,
                                                                            .viewName: Analytics.ViewName.onboardingTutorial.rawValue])
    }
    
    func logTutorialSwipe() {
        appContext.analyticsService.log(event: .didSwipeTutorialPage, withParameters: [.pageNum : String(currentPage + 1),
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
    }
}

@available(iOS 17, *)
#Preview {
    UserDefaults.onboardingNavigationInfo = nil
    
    return OnboardingNavigationController.instantiate(flow: .newUser(subFlow: nil))
}
