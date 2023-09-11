//
//  DomainsCollectionViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

@MainActor
protocol DomainsCollectionViewProtocol: BaseViewControllerProtocol {
    func setGoToSettingsTutorialHidden(_ isHidden: Bool)
    func setSettingsButtonHidden(_ isHidden: Bool)
    func setScanButtonHidden(_ isHidden: Bool)
    func setBackgroundImage(_ image: UIImage?)
    func setEmptyState(hidden: Bool)
    func setSelectedDomain(_ domain: DomainDisplayInfo, at index: Int, animated: Bool)
    func runConfettiAnimation()
    func setTitle(_ title: String?)
    func setNumberOfSteps(_ numberOfSteps: Int)
    func showToast(_ toast: Toast)
    func showMintingDomains(_ mintingDomains: [DomainDisplayInfo])
    func setAddButtonHidden(_ isHidden: Bool, isMessagingAvailable: Bool)
    func setUnreadMessagesCount(_ unreadMessagesCount: Int)
}

@MainActor
final class DomainsCollectionViewController: BaseViewController, TitleVisibilityAfterLimitNavBarScrollingBehaviour, BlurVisibilityAfterLimitNavBarScrollingBehaviour {

    @IBOutlet private weak var pageViewControllerContainer: UIView!
    @IBOutlet private weak var pageViewControllerGradientView: GradientView!

    @IBOutlet private weak var scanButton: FABButton!
    @IBOutlet private weak var goToSettingsContainerView: UIView!
    @IBOutlet private weak var backgroundImageContainer: UIView!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    
    @IBOutlet private weak var confettiContainerView: UIView!
    @IBOutlet private weak var confettiImageView: ConfettiImageView!
    @IBOutlet private weak var confettiGradientView: GradientView!
    
    @IBOutlet private weak var emptyStateContainerView: UIView!
    @IBOutlet private weak var emptyStateView: DomainsCollectionEmptyStateView!
    @IBOutlet private weak var importFromSiteButton: UDConfigurableButton!
    
    @IBOutlet private weak var underCardControl: DomainCollectionUnderCardControl!
    
    override var isObservingKeyboard: Bool { true }
    override var scrollableContentYOffset: CGFloat? { DomainsCollectionUICache.shared.collectionScrollableContentYOffset() }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var navBackStyle: BaseViewController.NavBackIconStyle { presenter.navBackStyle }
        
    private var defaultBottomOffset: CGFloat { Constants.scrollableContentBottomOffset }
    private var pageViewController: DomainsCollectionPageViewController!
    private var messagingButton: DomainsCollectionMessagingBarButton?
    private var currentOffset: CGPoint = CGPoint(x: 0,
                                                 y: -DomainsCollectionCarouselItemViewController.scrollViewTopInset)
    private var cardState: CarouselCardState = .expanded
    private var titleView: DomainsCollectionTitleView!
    private var setSearchUnderCardControlStateWorkingItem: DispatchWorkItem?
    private var didShowSwipeDomainCardTutorial = UserDefaults.didShowSwipeDomainCardTutorial
    private var havingMintingDomains = false
    
    var presenter: DomainsCollectionPresenterProtocol!

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.viewWillAppear()
    }
     
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presenter.viewDidAppear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        presenter.viewDidDisappear()
    }
    
    override func customScrollingBehaviour(yOffset: CGFloat, in navBar: CNavigationBar) -> (()->())? {
        { [weak self, weak navBar] in
            guard let self,
                  let navBar else { return }
            
            self.updateTitleVisibility(for: yOffset, in: navBar, cardState: self.cardState)
            self.updateBlurVisibility(for: yOffset, in: navBar)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupCollectionUICache()
        let domainCardY = DomainsCollectionUICache.shared.underCardControlY()
        underCardControl.center = self.view.localCenter
        underCardControl.frame.origin.y = domainCardY
    }
}

// MARK: - DomainsCollectionViewProtocol
extension DomainsCollectionViewController: DomainsCollectionViewProtocol {
    func setGoToSettingsTutorialHidden(_ isHidden: Bool) {
        goToSettingsContainerView.isHidden = isHidden
    }
    
    func setSettingsButtonHidden(_ isHidden: Bool) {
        if isHidden {
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem = nil
                cNavigationController?.updateNavigationBar()
            }
        } else {
            if navigationItem.leftBarButtonItem == nil {
                addSettingsButton()
                cNavigationController?.updateNavigationBar()
            }
        }
    }
  
    func setScanButtonHidden(_ isHidden: Bool) {
        scanButton.isHidden = isHidden
    }
    
    func setBackgroundImage(_ image: UIImage?) {
        let animationDuration: TimeInterval = 0.25
        UIView.transition(with: backgroundImageView,
                          duration: animationDuration,
                          options: .transitionCrossDissolve,
                          animations: { self.backgroundImageView.image = image },
                          completion: nil)
        
        UIView.animate(withDuration: animationDuration) {
            self.backgroundImageContainer.alpha = image == nil ? 0.0 : 1.0
        }
    }
    
    func setEmptyState(hidden: Bool) {
        emptyStateContainerView.isHidden = hidden
        pageViewControllerContainer.isHidden = !hidden
        underCardControl.isHidden = !hidden
        if hidden {
            setUnderCardControlVisibility()
        }
    }
    
    func setSelectedDomain(_ domain: DomainDisplayInfo, at index: Int, animated: Bool) {
        setStepForDomain(domain, at: index, animated: animated)
        pageControlDidSetIndex(index, isInteractive: false)
        underCardControl.setCurrentPage(index)
    }
    
    func runConfettiAnimation() {
        UIView.animate(withDuration: 1) { [weak self] in 
            self?.confettiContainerView.alpha = 1
        }
        confettiImageView.startConfettiAnimationAsync()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            UIView.animate(withDuration: 1) {
                self?.confettiContainerView.alpha = 0
            } completion: { _ in
                self?.confettiImageView.stopConfettiAnimation()
                ConfettiImageView.releaseAnimations()
            }
        }
    }
    
    func setTitle(_ title: String?) {
        navigationItem.titleView = nil
        self.title = title
        cNavigationController?.updateNavigationBar()
    }
    
    func setNumberOfSteps(_ numberOfSteps: Int) {
        underCardControl.setNumberOfPages(numberOfSteps)
        setUnderCardControlVisibility()
    }
    
    func setUnderCardControlVisibility() {
        underCardControl.isHidden = underCardControl.numberOfPages <= 1
    }
    
    func showToast(_ toast: Toast) {
        switch cardState {
        case .expanded:
            appContext.toastMessageService.showToast(toast,
                                                     in: underCardControl,
                                                     at: .center,
                                                     isSticky: false,
                                                     dismissDelay: nil,
                                                     action: nil)
        case .collapsed, .notVisible:
            appContext.toastMessageService.showToast(toast, isSticky: false)
        }
    }
    
    func showMintingDomains(_ mintingDomains: [DomainDisplayInfo]) {
        havingMintingDomains = !mintingDomains.isEmpty
        titleView.setMintingDomains(mintingDomains)
        setTitleViewFor(cardState: cardState)
    }
    
    func setAddButtonHidden(_ isHidden: Bool,
                            isMessagingAvailable: Bool) {
        if isHidden {
            if navigationItem.rightBarButtonItems != nil {
                navigationItem.rightBarButtonItems = nil
                cNavigationController?.updateNavigationBar()
            }
        } else {
            let expectedNumberOfBarButtons = isMessagingAvailable ? 2 : 1
            if navigationItem.rightBarButtonItems?.count != expectedNumberOfBarButtons {
                addRightBarButtons(isMessagingAvailable: isMessagingAvailable)
                cNavigationController?.updateNavigationBar()
            }
        }
    }
    
    func setUnreadMessagesCount(_ unreadMessagesCount: Int) {
        messagingButton?.setUnreadMessagesCount(unreadMessagesCount)
    }
}

// MARK: - DomainCollectionCarouselViewControllerDelegate
extension DomainsCollectionViewController: DomainsCollectionCarouselViewControllerDelegate {
    func carouselViewController(_ viewController: DomainsCollectionCarouselViewController, didScrollIn scrollView: UIScrollView) {
        guard viewController.page == currentStep else { return }
        
        let offset = scrollView.contentOffset
        currentOffset = offset
        for vc in getCurrentCarouselViewControllers() where vc !== viewController {
            vc.updateScrollOffset(offset)
        }
        adjustPageViewControllerGradientViewVisibility()
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
        adjustUnderCardControlVisibility(yOffset: scrollView.offsetRelativeToInset.y)
    }
    
    func carouselViewController(_ viewController: DomainsCollectionCarouselViewController, didFinishScrollingAt offset: CGPoint) {
        guard viewController.page == currentStep else { return }
        
        if let targetPoint = updateCardStateAndCalculateFinalPoint(for: offset.y,
                                                                   currentY: nil,
                                                                   velocity: nil,
                                                                   in: viewController.collectionView) {
            for vc in getCurrentCarouselViewControllers() {
                UIView.animate(withDuration: 0.08, delay: 0) {
                    vc.collectionView.contentOffset = targetPoint
                }
            }
        }
        applyCurrentCardState()
    }
    
    func carouselViewController(_ viewController: DomainsCollectionCarouselViewController, willEndDraggingAtTargetContentOffset targetContentOffset: CGPoint, velocity: CGPoint, currentContentOffset: CGPoint) -> CGPoint? {
        guard viewController.page == currentStep else { return nil }
        
        if let targetPoint = updateCardStateAndCalculateFinalPoint(for: targetContentOffset.y,
                                                                   currentY: currentContentOffset.y,
                                                                   velocity: velocity,
                                                                   in: viewController.collectionView) {
            return targetPoint
        }
        
        return nil
    }
    
    func updatePagesVisibility() {
        pageViewControllerDidScroll(pageViewController.scrollView)
    }
}

// MARK: - DomainsCollectionCarouselViewControllerActionsDelegate
extension DomainsCollectionViewController: DomainsCollectionCarouselViewControllerActionsDelegate {
    func didOccurUIAction(_ action: DomainsCollectionCarouselItemViewController.Action) {
        switch action {
        case .recentActivityLearnMore:
            presenter.didOccureUIAction(.recentActivityLearnMore)
        case .domainSelected(let domain):
            presenter.didOccureUIAction(.domainSelected(domain))
        case .nftSelected(let nft):
            presenter.didOccureUIAction(.nftSelected(nft))
        case .domainNameCopied:
            showToast(.domainCopied)
        case .rearrangeDomains:
            presenter.didOccureUIAction(.rearrangeDomains)
        case .parkedDomainLearnMore:
            presenter.didOccureUIAction(.parkedDomainLearnMore)
        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension DomainsCollectionViewController: DomainsCollectionPageViewControllerDataSource {
    func pageViewController(_ pageViewController: DomainsCollectionPageViewController, viewControllerAt index: Int) -> UIViewController? {
        guard let domain = presenter.domain(at: index) else { return nil }
        
        return getContainerItemForDomain(domain, at: index)
    }
    
    func pageViewController(_ pageViewController: DomainsCollectionPageViewController, canMoveTo index: Int) -> Bool {
        presenter.canMove(to: index)
    }
}

// MARK: - DomainsCollectionEmptyStateViewDelegate
extension DomainsCollectionViewController: DomainsCollectionEmptyStateViewDelegate {
    func didTapEmptyListItemOf(itemType: DomainsCollectionEmptyStateView.EmptyListItemType) {
        presenter.didOccureUIAction(.emptyListItemType(itemType))
    }
}

// MARK: - CustomPageViewControllerDelegate
extension DomainsCollectionViewController: DomainsCollectionPageViewControllerDelegate {
    func pageViewController(_ pageViewController: DomainsCollectionPageViewController, willAnimateToDirection direction: DomainsCollectionPageViewController.NavigationDirection) {
        pageControlDidSetIndex(pageViewController.currentIndex, isInteractive: true)
    }
    
    func pageViewController(_ pageViewController: DomainsCollectionPageViewController, didFinishAnimatingToDirection direction: DomainsCollectionPageViewController.NavigationDirection) {
        self.setSearchUnderCardControlStateWorkingItem?.cancel()
        let setSearchUnderCardControlStateWorkingItem = DispatchWorkItem { [weak self] in
            self?.underCardControl.setState(.search)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7,
                                      execute: setSearchUnderCardControlStateWorkingItem)
        self.setSearchUnderCardControlStateWorkingItem = setSearchUnderCardControlStateWorkingItem
        if let domain = presenter.domain(at: pageViewController.currentIndex) {
            logAnalytic(event: .didSwipeToDomain, parameters: [.domainName: domain.name])
        }
    }
    
    func pageViewControllerWillScroll(_ scrollView: UIScrollView) {
        setSearchUnderCardControlStateWorkingItem?.cancel()
        underCardControl.setState(.pageControl(page: currentStep))
    }
    
    func pageViewControllerDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        
        let cardFractionalWidth = DomainsCollectionCarouselItemViewController.cardFractionalWidth
        let cellSideOffset = (UIScreen.main.bounds.width * (1 - cardFractionalWidth)) / 2
        let cellWidth = UIScreen.main.bounds.width * cardFractionalWidth
        let centerX = offset.x + cellSideOffset + (cellWidth / 2)
        
        let viewControllers = getCurrentCarouselViewControllers()
        
        for viewController in viewControllers {
            let view = viewController.view!
            let frameInScroll = view.convert(view.bounds, to: scrollView)
            
            let cellCenterX = frameInScroll.minX + (frameInScroll.width / 2)
            let shiftFromCenterRatio: CGFloat = (abs(centerX - cellCenterX)) / cellWidth /// 0...1 - Relative to cell width
            
            let visibilityLevel = CarouselCellVisibilityLevel(shiftFromCenterRatio: shiftFromCenterRatio, isBehind: cellCenterX < centerX)
            viewController.updateVisibilityLevel(visibilityLevel)
        }
    }
    
    func pageViewController(_ pageViewController: DomainsCollectionPageViewController, didAddViewController viewController: UIViewController)  {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in /// Workaround for async nature of collection view reload data implementation
            if let self,
               let carouselItem = viewController as? DomainsCollectionCarouselItemViewController {
                carouselItem.updateScrollOffset(self.currentOffset)
            }
        }
    }
}

// MARK: - DomainsCollectionTitleViewDelegate
extension DomainsCollectionViewController: DomainsCollectionTitleViewDelegate {
    func domainsCollectionTitleView(_ domainsCollectionTitleView: DomainsCollectionTitleView, mintingDomainSelected mintingDomain: DomainDisplayInfo) {
        presenter.didOccureUIAction(.mintingDomainSelected(mintingDomain))
    }
    
    func domainsCollectionTitleViewShowMoreMintedDomainsPressed(_ domainsCollectionTitleView: DomainsCollectionTitleView) {
        presenter.didOccureUIAction(.mintingDomainsShowMoreMintedDomainsPressed)
    }
}

// MARK: - DomainCollectionUnderCardControlDelegate
extension DomainsCollectionViewController: DomainCollectionUnderCardControlDelegate {
    func domainCollectionUnderCardControlSearchButtonPressed(_ domainCollectionUnderCardControl: DomainCollectionUnderCardControl) {
        presenter.didOccureUIAction(.searchPressed)
    }
}

// MARK: - InteractivePushNavigation
extension DomainsCollectionViewController: CNavigationControllerChildTransitioning {
    func pushAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if viewController is QRScannerViewController {
            return CNavigationControllerSlidePushAnimation()
        }
        return nil
    }
    
    func pushNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if viewController is QRScannerViewController {
            return CNavigationBarSlidePushAnimation()
        }
        return nil
    }
}

// MARK: - Vertical scrolling behaviours
private extension DomainsCollectionViewController {
    func updateCardStateAndCalculateFinalPoint(for targetY: CGFloat,
                                               currentY: CGFloat?,
                                               velocity: CGPoint?,
                                               in collectionView: UICollectionView) -> CGPoint? {
        if let y = updateCardStateAndCalculateYCoordinate(for: targetY,
                                                          currentY: currentY,
                                                          velocity: velocity,
                                                          in: collectionView) {
            return CGPoint(x: collectionView.contentOffset.x,
                           y: y - collectionView.contentInset.top)
        }
        return nil
    }
    
    func updateCardStateAndCalculateYCoordinate(for targetY: CGFloat,
                                                currentY: CGFloat?,
                                                velocity: CGPoint?,
                                                in collectionView: UICollectionView) -> CGFloat? {
        let cellHeight = DomainsCollectionUICache.shared.cardFullHeight()
        let cellMaxY = cellHeight + collectionView.contentInset.top + 25 // Distance to spacer (24) + spacer height (1)
        let minHeight = DomainsCollectionCarouselCardCell.minHeight
        
        func setExpandedState() -> CGFloat {
            /// Scroll to the top
            setCardState(.expanded)
            return 0
        }
        
        func setCollapsedState() -> CGFloat {
            /// Scroll to show collapsed card
            setCardState(.collapsed)
            return cellHeight - minHeight
        }
        
        func setNotVisibleState() -> CGFloat {
            /// Scroll to the top of next section
            setCardState(.notVisible)
            return cellMaxY
        }
        
        if targetY > cellMaxY {
            if let currentY,
               currentY < cellHeight {
                return setNotVisibleState()
            }
            setCardState(.notVisible)
            /// Keep default behaviour
            return nil
        }
        
        if targetY > cellHeight - (minHeight / 2) {
            return setNotVisibleState()
        } else {
            let collapsableHeight = cellHeight - minHeight
            let scrollingOffset = targetY / collapsableHeight
            
            if let velocity {
                if velocity.y > 0 { // Scroll down
                    switch cardState {
                    case .expanded:
                        return setCollapsedState()
                    case .collapsed:
                        return setNotVisibleState()
                    case .notVisible:
                        return nil
                    }
                } else {
                    switch cardState {
                    case .notVisible:
                        return setCollapsedState()
                    case .collapsed:
                        return setExpandedState()
                    case .expanded:
                        return nil
                    }
                }
            } else {
                if scrollingOffset > 0.5 {
                    return setCollapsedState()
                } else {
                    return setExpandedState()
                }
            }
        }
    }
    
    func setCardState(_ cardState: CarouselCardState) {
        setTitleViewFor(cardState: cardState)
        self.cardState = cardState
        let viewControllers = getCurrentCarouselViewControllers()
        for viewController in viewControllers {
            viewController.setCarouselCardState(cardState)
        }
    }
    
    func setTitleViewFor(cardState: CarouselCardState) {
        let currentCardState = self.cardState
        func updateState() {
            if havingMintingDomains {
                titleView.setState(.mintingInProgress)
            } else {
                if !self.didShowSwipeDomainCardTutorial {
                    switch cardState {
                    case .expanded:
                        /// User was in collapsed state and swipe back to expanded. Tutorial is over.
                        if currentCardState != .expanded {
                            UserDefaults.didShowSwipeDomainCardTutorial = true
                            self.didShowSwipeDomainCardTutorial = true
                            titleView.setState(.domainInfo)
                        } else {
                            titleView.setState(.swipeTutorial)
                        }
                    case .collapsed:
                        titleView.setState(.swipeTutorial)
                    case .notVisible:
                        titleView.setState(.domainInfo)
                    }
                } else {
                    titleView.setState(.domainInfo)
                }
            }
        }
        
        if let navBar = cNavigationBar {
            let yOffset = getCurrentCarouselViewControllers().first?.contentOffsetRelativeToInset.y ?? currentOffset.y
            updateTitleVisibility(for: yOffset, in: navBar, cardState: cardState)
        }
        
        /// Check for nav bar visibility.
        /// If nav bar hidden, wait for it will disappear before updating title state
        if cNavigationBar?.isTitleHidden == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + CNavigationBar.animationDuration) {
                updateState()
            }
        } else {
            updateState()
        }
    }
    
    func updateTitleVisibility(for yOffset: CGFloat,
                               in navBar: CNavigationBar,
                               cardState: CarouselCardState) {
        guard cNavigationController?.topViewController == self else { return }
        
        if havingMintingDomains {
            setNavBarTitleViewHidden(false, in: navBar)
        } else if !didShowSwipeDomainCardTutorial {
            switch cardState {
            case .expanded:
                setNavBarTitleViewHidden(true, in: navBar)
            case .collapsed, .notVisible:
                setNavBarTitleViewHidden(false, in: navBar)
            }
        } else {
            let limit = domainCardMaxYPosition()
            updateTitleViewVisibility(for: yOffset, in: navBar, limit: limit)
        }
    }
    
    func applyCurrentCardState() {
        let viewControllers = getCurrentCarouselViewControllers()
        let decelerationRate = decelerationRate(for: cardState)
        
        for viewController in viewControllers {
            viewController.updateDecelerationRate(decelerationRate)
        }
    }
    
    func decelerationRate(for cardState: CarouselCardState) -> UIScrollView.DecelerationRate {
        let value: CGFloat
        switch cardState {
        case .expanded, .collapsed:
            value = 0.99
            pageViewController.setScrollingEnabled(true)
        case .notVisible:
            value = 1
            pageViewController.setScrollingEnabled(false)
        }
        return .init(rawValue: value)
    }
}

// MARK: - Actions
private extension DomainsCollectionViewController {
    @IBAction func didPressScanButton(_ sender: Any) {
        presenter.didPressScanButton()
    }
    
    @IBAction func importDomainsFromWebPressed() {
        logButtonPressedAnalyticEvents(button: .importFromTheWebsite)
        presenter.importDomainsFromWebPressed()
    }

    @objc func didTapSettingsButton() {
        logButtonPressedAnalyticEvents(button: .settings)
        UDVibration.buttonTap.vibrate()
        presenter.didTapSettingsButton()
    }
    
    @objc func didTapAddButton() {
        logButtonPressedAnalyticEvents(button: .plus)
        UDVibration.buttonTap.vibrate()
        presenter.didTapAddButton()
    }
    
    @objc func didTapMessagingButton() {
        logButtonPressedAnalyticEvents(button: .messaging)
        UDVibration.buttonTap.vibrate()
        presenter.didTapMessagingButton()
    }
}

// MARK: - Private methods
private extension DomainsCollectionViewController {
    var currentStep: Int { presenter.currentIndex }

    func getContainerItemForDomain(_ domain: DomainDisplayInfo, at index: Int) -> DomainsCollectionCarouselViewController? {
        let itemVC = DomainsCollectionCarouselItemViewController.instantiate(domain: domain,
                                                                             cardState: cardState,
                                                                             containerViewController: self,
                                                                             actionsDelegate: self)
        itemVC.page = index
        itemVC.delegate = self
        
        return itemVC
    }
    
    func pageControlDidSetIndex(_ index: Int, isInteractive: Bool) {
        presenter.didMove(to: index)
        if isInteractive {
            underCardControl.setState(.pageControl(page: index))
        }
        if let domain = presenter.domain(at: index) {
            titleView.setWith(domain: domain)
        }
    }
    
    func getCurrentCarouselViewControllers() -> [DomainsCollectionCarouselViewController] {
        pageViewController.viewControllers.compactMap({ $0 as? DomainsCollectionCarouselViewController })
    }
    
    func adjustPageViewControllerGradientViewVisibility() {
        let yOffset = max(0, currentOffset.y)
        let offsetToGradientRatio = min(1, yOffset / pageViewControllerGradientView.bounds.height)
        let gradientAlpha = 1 - offsetToGradientRatio
        pageViewControllerGradientView.alpha = gradientAlpha
    }
    
    func domainCardMaxYPosition() -> CGFloat {
        DomainsCollectionUICache.shared.cardHeightWithTopInset() 
    }
    
    func adjustUnderCardControlVisibility(yOffset: CGFloat) {
        let underControlHeight = self.underCardControl.bounds.height
        var offsetToHeightRatio = abs(yOffset) / underControlHeight
        offsetToHeightRatio = min(1, offsetToHeightRatio)
        let alpha = 1 - offsetToHeightRatio
        underCardControl.alpha = alpha
    }
}

// MARK: - Setup methods
private extension DomainsCollectionViewController {
    func setup() {
        setupConfettiAnimation()
        setupEmptyView()
        setupPageViewController()
        setupNavBar()
        setAddButtonHidden(true, isMessagingAvailable: false)
        scanButton.setTitle(String.Constants.login.localized(), image: .scanQRIcon20)
        scanButton.applyFigmaShadow(style: .medium)
        setScanButtonHidden(true)
        setBackgroundImage(nil)
        setGoToSettingsTutorialHidden(true)
        emptyStateView.delegate = self
        underCardControl.delegate = self
    }
    
    func setupNavBar() {
        titleView = DomainsCollectionTitleView(frame: .zero)
        titleView.delegate = self
        setTitleViewFor(cardState: cardState)
        navigationItem.titleView = titleView
    }
    
    func addRightBarButtons(isMessagingAvailable: Bool) {
        let addBarButton = UIBarButtonItem(image: .plusIconNav, style: .plain, target: self, action: #selector(didTapAddButton))
        addBarButton.tintColor = .foregroundDefault
        addBarButton.accessibilityIdentifier = "Domains Collection Plus Button"
        
        if isMessagingAvailable {
            let messagingButton = DomainsCollectionMessagingBarButton()
            messagingButton.pressedCallback = { [weak self] in self?.didTapMessagingButton() }
            self.messagingButton = messagingButton
            let messagingBarButton = UIBarButtonItem(customView: messagingButton)
            
            navigationItem.rightBarButtonItems = [addBarButton, messagingBarButton]
        } else {
            navigationItem.rightBarButtonItems = [addBarButton]
        }
    }

    func addSettingsButton() {
        let leftBarButton = UIBarButtonItem(image: UIImage(named: "gearIcon"), style: .plain, target: self, action: #selector(didTapSettingsButton))
        leftBarButton.tintColor = .foregroundDefault
        leftBarButton.accessibilityIdentifier = "Domains Collection Settings Button"
        navigationItem.leftBarButtonItem = leftBarButton
    }
  
    func setupEmptyView() {
        importFromSiteButton.setConfiguration(.largeGhostPrimaryButtonConfiguration)
        importFromSiteButton.setTitle(String.Constants.claimDomainsToSelfCustodial.localized(), image: nil)
    }
    
    func setupConfettiAnimation() {
        confettiContainerView.alpha = 0
        confettiImageView.setGradientHidden(true)
        confettiGradientView.gradientDirection = .topToBottom
        confettiGradientView.gradientColors = [.backgroundDefault.withAlphaComponent(0.01), .backgroundDefault, .backgroundDefault]
    }
    
    func setupPageViewController() {
        guard pageViewController == nil else { return }
        
        pageViewControllerContainer.backgroundColor = .clear
        
        pageViewController = DomainsCollectionPageViewController()
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        addChild(pageViewController)
        pageViewController.view.backgroundColor = UIColor.clear
        pageViewController.view.embedInSuperView(pageViewControllerContainer)
        pageViewController.didMove(toParent: self)
    }
    
    func setStepForDomain(_ domain: DomainDisplayInfo,
                          at index: Int,
                          animated: Bool = true) {
        if let step = getContainerItemForDomain(domain, at: index) {
            pageViewController.setViewController(step,
                                                 animated: animated,
                                                 index: index, completion: { [weak self] in
                self?.pageViewController.prepareForNextViewControllerForDirection(.forward, animationStyle: .fade)
                self?.pageViewController.prepareForNextViewControllerForDirection(.reverse, animationStyle: .fade)
            })
        }
    }
    
    func setupCollectionUICache() {
        let collectionViewYInContainer = pageViewControllerContainer.convert(pageViewControllerContainer.frame.origin, to: view).y
        DomainsCollectionUICache.shared.set(collectionViewYInContainer: collectionViewYInContainer)
        DomainsCollectionUICache.shared.setCollectionViewHeight(pageViewControllerContainer.bounds.height)
    }
}

extension DomainsCollectionViewController {
    enum Action {
        case emptyListItemType(_ type: DomainsCollectionEmptyStateView.EmptyListItemType)
        case recentActivityLearnMore
        case domainSelected(_ domain: DomainDisplayInfo)
        case nftSelected(_ nft: NFTModel)
        case mintingDomainSelected(_ domain: DomainDisplayInfo)
        case mintingDomainsShowMoreMintedDomainsPressed
        case rearrangeDomains
        case searchPressed
        case parkedDomainLearnMore
    }
}
