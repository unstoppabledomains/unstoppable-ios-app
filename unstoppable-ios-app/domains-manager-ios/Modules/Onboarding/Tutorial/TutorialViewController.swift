//
//  TutorialViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 13.03.2022.
//

import UIKit
import SwiftUI

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
    
    private var createNewWalletButton = UDConfigurableButton()
    private var progressView = DashesProgressView()
    private var currentPage = 0
    private var progress: Double = 0.0
    private var displayLink: CADisplayLink?
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopDisplayLink()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presenter.viewDidAppear()
        appContext.analyticsService.log(event: .viewDidAppear, withParameters: [.viewName: Analytics.ViewName.onboardingTutorial.rawValue])
        setupDisplayLink()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupNavProgressViewFrame()
    }
}

// MARK: - TutorialViewControllerProtocol
extension TutorialViewController: TutorialViewControllerProtocol { }

// MARK: - UIPageViewControllerDelegate
extension TutorialViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        currentPage = orderedViewControllers.firstIndex(of: pageContentViewController)!
        progress = (Double(currentPage)) / Double(orderedViewControllers.count)
        self.progressView.setProgress(progress)
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
    func didPressCreateNewWalletButton() {
        logButtonPressedAnalyticEvents(button: .createVault)
        presenter?.didPressCreateNewWalletButton()
    }
    
    func didPressAddExistingWalletButton() {
        logButtonPressedAnalyticEvents(button: .addWallet)
        presenter?.didPressAddExistingWalletButton()
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
        setupActionButtons()
        setupNavigationBar()
        view?.addSubview(progressView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupWelcomeMessage()
            self.setupDisplayLink()
        }
    }
    
    func setupView() {
        view.backgroundColor = .backgroundDefault
    }
    
    func setupDelegates() {
        self.dataSource = self
        self.delegate = self
    }
    
    func setupActionButtons() {
        let isIPSE = deviceSize.isIPSE

        let addExistingButtonTitle = isIPSE ? String.Constants.existingWallet : String.Constants.connectWalletTitle
        let addExistingWalletButtonViewContainer = createAndAddUDButton(title: addExistingButtonTitle.localized(),
                                                                        style: .large(.raisedPrimary)) { [weak self] in
            self?.didPressAddExistingWalletButton()
        }
        
        let createNewButtonTitle = isIPSE ? String.Constants.newWallet : String.Constants.createNewWallet
        let createNewWalletButtonViewContainer = createAndAddUDButton(title: createNewButtonTitle.localized(),
                                                                      style: .large(.raisedTertiary)) { [weak self] in
            self?.didPressCreateNewWalletButton()
        }
        
        var buttons = [addExistingWalletButtonViewContainer, createNewWalletButtonViewContainer]
        if isIPSE {
            buttons = buttons.reversed()
        }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 16
        stack.axis = isIPSE ? .horizontal : .vertical
        if isIPSE {
            stack.distribution = .fillEqually
        }
        
        view.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                                     stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)])
    }
    
    func createAndAddUDButton(title: String,
                              style: UDButtonStyle, 
                              action: @escaping EmptyCallback) -> UIView {
        let buttonView = UDButtonView(text: title,
                                                       style: style) {
            action()
        }
        let buttonViewController = UIHostingController(rootView: buttonView)
        let buttonViewContainer = UIView()
        addChildViewController(buttonViewController, andEmbedToView: buttonViewContainer)
        return buttonViewContainer
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
        guard let navBar = cNavigationBar else { return }

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
    
    func setupNavProgressViewFrame() {
        guard let navBar = cNavigationBar else { return }
        
        let navBarHeight: CGFloat = navBar.bounds.height
        let contentHeightHalf: CGFloat = navBar.navBarContentView.bounds.height / 2
        let progressViewHalf: CGFloat = progressView.frame.height / 2
        progressView.frame.origin.y = navBarHeight - contentHeightHalf - progressViewHalf
    }
    
    func setupDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc func handleDisplayLink(_ displayLink: CADisplayLink) {
        let animationDurationOfStep: Double = 3
        let numberOfSteps = orderedViewControllers.count
        let totalAnimationDuration = animationDurationOfStep * Double(numberOfSteps)
        let tickDuration = displayLink.duration / totalAnimationDuration
        progress += tickDuration
        if progress >= 1 {
            progress = 0
        }
        
        let oneStepProgress: Double = 1/3
        let currentStep = Int(progress / oneStepProgress)
        if currentStep != self.currentPage {
            let vc = orderedViewControllers[currentStep]
            let isForward = currentStep > self.currentPage
            setViewControllers([vc],
                               direction: isForward ? .forward : .reverse,
                               animated: true,
                               completion: nil)
            self.currentPage = currentStep
        }
        progressView.setProgress(progress)
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
        
        @MainActor
        var image: UIImage {
            let isIPSE = deviceSize.isIPSE
            switch self {
            case .tutorialScreen1: return isIPSE ? #imageLiteral(resourceName: "tutorialIllustration1SE") :  #imageLiteral(resourceName: "tutorialIllustration1")
            case .tutorialScreen2: return isIPSE ? #imageLiteral(resourceName: "tutorialIllustration2SE") :  #imageLiteral(resourceName: "tutorialIllustration2")
            case .tutorialScreen3: return isIPSE ? #imageLiteral(resourceName: "tutorialIllustration3SE") :  #imageLiteral(resourceName: "tutorialIllustration3")
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
