//
//  DomainsCollectionViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

@MainActor
protocol DomainsCollectionViewProtocol: BaseCollectionViewControllerProtocol {
    func setGoToSettingsTutorialHidden(_ isHidden: Bool)
    func setVisualisationControlHidden(_ isHidden: Bool)
    func setVisualisationControlSelectedSegmentIndex(_ selectedSegmentIndex: Int)
    func setSettingsButtonHidden(_ isHidden: Bool)
    func setAddButtonHidden(_ isHidden: Bool)
    func setScanButtonHidden(_ isHidden: Bool)
    func setBackgroundImage(_ image: UIImage?)
    func setEmptyState(hidden: Bool)
    func setLayout(_ layout: UICollectionViewLayout)
    func applySnapshot(_ snapshot: DomainsCollectionSnapshot, animated: Bool)
    func runConfettiAnimation()
    func setTitle(_ title: String?)
}

typealias DomainsCollectionDataSource = UICollectionViewDiffableDataSource<DomainsCollectionViewController.Section, DomainsCollectionViewController.Item>
typealias DomainsCollectionSnapshot = NSDiffableDataSourceSnapshot<DomainsCollectionViewController.Section, DomainsCollectionViewController.Item>
 
@MainActor
final class DomainsCollectionViewController: BaseViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var scanButton: FABButton!
    @IBOutlet private weak var goToSettingsContainerView: UIView!
    @IBOutlet private weak var backgroundImageContainer: UIView!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    
    @IBOutlet private weak var confettiContainerView: UIView!
    @IBOutlet private weak var confettiImageView: ConfettiImageView!
    @IBOutlet private weak var confettiGradientView: GradientView!
    
    @IBOutlet private weak var emptyStateView: UIView!
    @IBOutlet private weak var emptyStateGradient: GradientView!
    
    
    private var visualisationControl: SegmentPicker!
    
    private var dataSource: DomainsCollectionDataSource!
    private var isNavBarVisible = false
    private var isScanBarHidden = false
    private var isSearching = false
    private var defaultBottomOffset: CGFloat { Constants.scrollableContentBottomOffset }

    var cellIdentifiers: [UICollectionViewCell.Type] { [DomainsCollectionEmptyCell.self,
                                                        DomainsCollectionCardCell.self,
                                                        DomainsCollectionListCell.self,
                                                        DomainsCollectionMintingInProgressCell.self,
                                                        DomainsCollectionSearchEmptyCell.self,
                                                        DomainsCollectionEmptyListCell.self,
                                                        DomainsCollectionEmptyTopInfoCell.self] }
    var presenter: DomainsCollectionPresenterProtocol!
    override var isObservingKeyboard: Bool { true }
    override var scrollableContentYOffset: CGFloat? { presenter.scrollableContentYOffset }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var navBackStyle: BaseViewController.NavBackIconStyle { presenter.navBackStyle }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
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

    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        collectionView.contentInset.bottom = keyboardHeight + defaultBottomOffset
    }
    
    override func keyboardWillHideAction(duration: Double, curve: Int) {
        collectionView.contentInset.bottom = defaultBottomOffset
    }
}

// MARK: - DomainsCollectionViewProtocol
extension DomainsCollectionViewController: DomainsCollectionViewProtocol {
    func setGoToSettingsTutorialHidden(_ isHidden: Bool) {
        goToSettingsContainerView.isHidden = isHidden
    }
    
    func setVisualisationControlHidden(_ isHidden: Bool) {
        visualisationControl.isHidden = isHidden
    }
    
    func setVisualisationControlSelectedSegmentIndex(_ selectedSegmentIndex: Int) {
        if cNavigationController?.topViewController == self,
           selectedSegmentIndex != visualisationControl.selectedSegmentIndex {
            cNavigationController?.navigationBar.setBlur(hidden: true, animated: false)
        }
        visualisationControl.selectedSegmentIndex = selectedSegmentIndex
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
    
    func setAddButtonHidden(_ isHidden: Bool) {
        if isHidden {
            if navigationItem.rightBarButtonItem != nil {
                navigationItem.rightBarButtonItem = nil
                cNavigationController?.updateNavigationBar()
            }
        } else {
            if navigationItem.rightBarButtonItem == nil {
                addAddBarButton()
                cNavigationController?.updateNavigationBar()
            }
        }
    }

    func setScanButtonHidden(_ isHidden: Bool) {
        self.isScanBarHidden = isHidden
        if !isSearching {
            resolveScanButtonHiddenForScrollState(isHidden)
        }
    }
    
    func setBackgroundImage(_ image: UIImage?) {
        backgroundImageContainer.isHidden = image == nil
        backgroundImageView.image = image
    }
    
    func setEmptyState(hidden: Bool) {
        emptyStateView.isHidden = hidden
    }
    
    func setLayout(_ layout: UICollectionViewLayout) {
        collectionView.collectionViewLayout = layout
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func applySnapshot(_ snapshot: DomainsCollectionSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
        if !isSearching {
            resolveScanButtonHiddenForScrollState(self.isScanBarHidden)
        }
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
}

// MARK: - InteractivePushNavigation
extension DomainsCollectionViewController: CNavigationControllerChildTransitioning {
    func nextViewControllerTransitioning() -> CNavigationControllerNextChildTransitioning? {
        guard presentedViewController == nil else { return nil }
        
        UDVibration.buttonTap.vibrate()
        if isScanBarHidden {
            return nil
        }
        let vc = UDRouter().buildQRScannerModule(qrRecognizedCallback: { Task { await self.presenter.didRecognizeQRCode() } })
        logAnalytic(event: .swipeToScanning)
        return .init(viewController: vc,
                     interactiveTransitionStartThreshold: 1)
    }
    
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

// MARK: - UICollectionViewDelegate
extension DomainsCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if visualisationControl.selectedSegmentIndex != 0 {
            cNavigationController?.underlyingScrollViewDidScroll(scrollView)
        }
        guard !isScanBarHidden,
              !isSearching,
              collectionView.contentSize.height > collectionView.bounds.height else { return }
        
        let bottomOffset = collectionView.contentSize.height - collectionView.bounds.height
        let lastCellOffset = bottomOffset - BaseListCollectionViewCell.height
        
        scanButton.isHidden = scrollView.contentOffset.y > lastCellOffset
    }
}

// MARK: - DomainsListSearchHeaderViewDelegate
extension DomainsCollectionViewController: DomainsListSearchHeaderViewDelegate {
    func willStartSearch(_ domainsListSearchHeaderView: DomainsListSearchHeaderView) {
        self.isSearching = true
        scanButton.isHidden = true
        presenter.didStartSearch()
        UDVibration.buttonTap.vibrate()
    }
    
    func didFinishSearch(_ domainsListSearchHeaderView: DomainsListSearchHeaderView) {
        self.isSearching = false
        scanButton.isHidden = isScanBarHidden
        collectionView.setContentOffset(.zero, animated: false)
        presenter.didStopSearch()
        UDVibration.buttonTap.vibrate()
    }
    
    func didSearchWith(key: String) {
        presenter.didSearchDomainsWith(key: key)
    }
}

// MARK: - Actions
private extension DomainsCollectionViewController {
    @IBAction func didPressScanButton(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .scan)
        presenter.didPressScanButton()
    }
    
    @objc func didChangeVisualisationMode(_ sender: SegmentPicker) {
        guard let visualisationType = DomainsVisualisation(rawValue: sender.selectedSegmentIndex) else { return }
        
        logButtonPressedAnalyticEvents(button: .homeTopControl, parameters: [.topControlType : visualisationType.analyticsName])
        presenter.didChangeDomainsVisualisation(visualisationType)
        collectionView.setContentOffset(CGPoint(x: 0,
                                                y: -collectionView.contentInset.top),
                                        animated: false)
        cNavigationController?.underlyingScrollViewDidScroll(collectionView)
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
}

// MARK: - Private methods
private extension DomainsCollectionViewController {
    func resolveScanButtonHiddenForScrollState(_ isHidden: Bool) {
        if isHidden {
            scanButton.isHidden = true
        } else {
            guard collectionView.contentSize.height > collectionView.bounds.height else {
                scanButton.isHidden = false
                return
            }
            
            let bottomOffset = collectionView.contentSize.height - collectionView.bounds.height
            let lastCellOffset = bottomOffset - BaseListCollectionViewCell.height
            
            scanButton.isHidden = collectionView.contentOffset.y > lastCellOffset
        }
    }
}

// MARK: - Setup methods
private extension DomainsCollectionViewController {
    func setup() {
        setupVisualisationControl()
        setupNavBar()
        setupConfettiAnimation()
        setupEmptyView()
        setupCollectionView()
        setAddButtonHidden(true)
        setScanButtonHidden(true)
        setBackgroundImage(nil)
        setVisualisationControlHidden(true)
        setGoToSettingsTutorialHidden(true)
    }
    
    func setupNavBar() {
        navigationItem.titleView = visualisationControl
 
        addAddBarButton()
    }
    
    func addAddBarButton() {
        let rightBarButton = UIBarButtonItem(image: .plusIconNav, style: .plain, target: self, action: #selector(didTapAddButton))
        rightBarButton.tintColor = .foregroundDefault
        rightBarButton.accessibilityIdentifier = "Domains Collection Plus Button"
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func addSettingsButton() {
        let leftBarButton = UIBarButtonItem(image: UIImage(named: "gearIcon"), style: .plain, target: self, action: #selector(didTapSettingsButton))
        leftBarButton.tintColor = .foregroundDefault
        leftBarButton.accessibilityIdentifier = "Domains Collection Settings Button"
        navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func setupVisualisationControl() {
        let visualisationControl = SegmentPicker()
        visualisationControl.accessibilityIdentifier = "Domains Collection Visualisation Control"
        self.visualisationControl = visualisationControl
        visualisationControl.addTarget(self, action: #selector(didChangeVisualisationMode(_:)), for: .valueChanged)
        
        for (i, vis) in DomainsVisualisation.allCases.enumerated() {
            visualisationControl.insertSegment(with: vis.icon, at: i, animated: false)
        }
    }
    
    func setupEmptyView() {
        emptyStateGradient.gradientDirection = .topToBottom
        emptyStateGradient.gradientColors = [.backgroundDefault, .backgroundDefault.withAlphaComponent(0.64)]
    }
    
    func setupConfettiAnimation() {
        confettiContainerView.alpha = 0
        confettiImageView.setGradientHidden(true)
        confettiGradientView.gradientDirection = .topToBottom
        confettiGradientView.gradientColors = [.backgroundDefault.withAlphaComponent(0.01), .backgroundDefault, .backgroundDefault]
    }
    
    func setupCollectionView() {
        collectionView.accessibilityIdentifier = "Domains Collection Collection View"
        collectionView.delegate = self
        collectionView.register(DomainsListSearchHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: DomainsListSearchHeaderView.reuseIdentifier)
        collectionView.contentInset.top = 27
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = DomainsCollectionDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .empty(let mintButtonPressed, let buyButtonPressed):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionEmptyCell.self, forIndexPath: indexPath)
                cell.mintButtonPressed = mintButtonPressed
                cell.buyButtonPressed = buyButtonPressed
                
                return cell
            case .emptyList(let item):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionEmptyListCell.self, forIndexPath: indexPath)
                cell.setWith(item: item)
                
                return cell
            case .emptyTopInfo:
                let cell = collectionView.dequeueCellOfType(DomainsCollectionEmptyTopInfoCell.self, forIndexPath: indexPath)

                return cell
            case .domainCardItem(let displayInfo):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionCardCell.self, forIndexPath: indexPath)
                cell.setWith(displayInfo: displayInfo)
                
                return cell
            case .domainListItem(let domainItem, let isUpdatingRecords, let isSelectable, let isReverseResolution):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionListCell.self, forIndexPath: indexPath)
                cell.setWith(domainItem: domainItem, isUpdatingRecords: isUpdatingRecords, isSelectable: isSelectable, isReverseResolution: isReverseResolution)
                
                return cell
            case .domainsMintingInProgress(let domainsCount):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionMintingInProgressCell.self, forIndexPath: indexPath)
                cell.setWith(domainsCount: domainsCount)
                
                return cell
            case .searchEmptyState:
                let cell = collectionView.dequeueCellOfType(DomainsCollectionSearchEmptyCell.self, forIndexPath: indexPath)
                
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: DomainsListSearchHeaderView.reuseIdentifier, for: indexPath) as! DomainsListSearchHeaderView
            view.delegate = self
            
            return view
        }
    }
}

extension DomainsCollectionViewController {
    enum Section: Hashable {
        case search, primary, other, minting, searchEmptyState, emptyTopInfo, emptyList(item: EmptyListItemType)
    }
    
    enum Item: Hashable {
        case empty(mintPressed: EmptyCallback, buyPressed: EmptyCallback)
        case emptyList(item: EmptyListItemType)
        case emptyTopInfo
        case domainCardItem(_ displayInfo: DomainCardDisplayInfo)
        case domainListItem(_ domainItem: DomainItem, isUpdatingRecords: Bool, isSelectable: Bool, isReverseResolution: Bool)
        case domainsMintingInProgress(domainsCount: Int)
        case searchEmptyState
        
        static func == (lhs: DomainsCollectionViewController.Item, rhs: DomainsCollectionViewController.Item) -> Bool {
            switch (lhs, rhs) {
            case (.empty, .empty):
                return true
            case (.emptyTopInfo, .emptyTopInfo):
                return true
            case (.emptyList(let lhsItem), .emptyList(let rhsItem)):
                return lhsItem == rhsItem
            case (.domainCardItem(let lItem), .domainCardItem(let rItem)):
                return lItem == rItem
            case (.domainListItem(let lItem, let lIsMinting, let lIsSelectable, let lhsIsReverseResolution), .domainListItem(let rItem, let rIsMinting, let rIsSelectable, let rhsIsReverseResolution)):
                return lItem == rItem && lIsMinting == rIsMinting && lIsSelectable == rIsSelectable && lhsIsReverseResolution == rhsIsReverseResolution
            case (.domainsMintingInProgress(let lDomainsCount), .domainsMintingInProgress(let rDomainsCount)):
                return lDomainsCount == rDomainsCount
            case (.searchEmptyState, .searchEmptyState):
                return true
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .empty:
                hasher.combine(0)
            case .emptyTopInfo:
                hasher.combine(1)
            case .emptyList(let item):
                hasher.combine(item)
            case .domainCardItem(let displayInfo):
                hasher.combine(displayInfo)
            case .domainListItem(let item, let isMinting, let isSelectable, let isReverseResolution):
                hasher.combine(item)
                hasher.combine(isMinting)
                hasher.combine(isSelectable)
                hasher.combine(isReverseResolution)
            case .domainsMintingInProgress(let domainsCount):
                hasher.combine(domainsCount)
            case .searchEmptyState:
                hasher.combine(10)
            }
        }
        
        struct DomainCardDisplayInfo: Hashable {
            let domainItem: DomainItem
            let isUpdatingRecords: Bool
            let didTapPrimaryDomain: Bool
        }
    }
    
    enum EmptyListItemType: Hashable, CaseIterable {
        case mintDomains, buyDomains, manageDomains
        
        var title: String {
            switch self {
            case .mintDomains:
                return String.Constants.domainsCollectionEmptyStateMintTitle.localized()
            case .buyDomains:
                return String.Constants.domainsCollectionEmptyStateBuyTitle.localized()
            case .manageDomains:
                return String.Constants.domainsCollectionEmptyStateManageSubtitle.localized()
            }
        }
        
        var subtitle: String {
            switch self {
            case .mintDomains:
                return String.Constants.domainsCollectionEmptyStateMintSubtitle.localized()
            case .buyDomains:
                return String.Constants.domainsCollectionEmptyStateBuySubtitle.localized()
            case .manageDomains:
                return String.Constants.domainsCollectionEmptyStateManageSubtitle.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .mintDomains:
                return .sparklesIcon
            case .buyDomains:
                return .cartIcon
            case .manageDomains:
                return .walletIcon
            }
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .mintDomains:
                return .mintDomains
            case .buyDomains:
                return .buyDomains
            case .manageDomains:
                return .manageDomains
            }
        }
    }
}

extension DomainsCollectionViewController {
    enum DomainsVisualisation: Int, CaseIterable {
        case card, list
        
        var icon: UIImage {
            switch self {
            case .card:
                return .domainsProfileIcon
            case .list:
                return UIImage(named: "domainsListIcon")!
            }
        }
        
        var analyticsName: String {
            switch self {
            case .card:
                return "card"
            case .list:
                return "list"
            }
        }
    }
}
