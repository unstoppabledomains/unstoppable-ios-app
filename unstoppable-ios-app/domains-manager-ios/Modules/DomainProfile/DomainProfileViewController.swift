//
//  DomainProfileViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import UIKit
import SwiftUI

@MainActor
protocol DomainProfileViewProtocol: BaseDiffableCollectionViewControllerProtocol & DomainProfileSectionViewProtocol & ViewWithDashesProgress where Section == DomainProfileViewController.Section, Item == DomainProfileViewController.Item {
    func setConfirmButtonHidden(_ isHidden: Bool, style: DomainProfileViewController.ActionButtonStyle)
    func set(title: String?)
    func setAvailableActionsGroups(_ actionGroups: [DomainProfileActionsGroup])
    func setBackgroundImage(_ image: UIImage?)
}

@MainActor
protocol DomainProfileSectionViewProtocol: BaseViewController {
    func scrollToItem(_ item: DomainProfileViewController.Item, atPosition position: UICollectionView.ScrollPosition, animated: Bool)
    func hideKeyboard()
}

typealias DomainProfileDataSource = UICollectionViewDiffableDataSource<DomainProfileViewController.Section, DomainProfileViewController.Item>
typealias DomainProfileSnapshot = NSDiffableDataSourceSnapshot<DomainProfileViewController.Section, DomainProfileViewController.Item>
typealias DomainProfileActionsGroup = [DomainProfileViewController.Action]

@MainActor
final class DomainProfileViewController: BaseViewController, TitleVisibilityAfterLimitNavBarScrollingBehaviour, BlurVisibilityAfterLimitNavBarScrollingBehaviour, PassthroughAfterLimitNavBarScrollingBehaviour {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var backgroundImageBlurView: UIVisualEffectView!
    @IBOutlet private weak var confirmUpdateButton: FABCounterButton!
    @IBOutlet private weak var confirmUpdateMainButton: RaisedWhiteButton!
    @IBOutlet private weak var confirmButtonGradientView: GradientView!
    @IBOutlet private weak var confirmButtonsContainerStack: UIStackView!
    @IBOutlet private weak var confirmButtonsContainerStackTopConstraint: NSLayoutConstraint!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [DomainProfileTopInfoCell.self,
                                                        DomainProfileGeneralInfoCell.self,
                                                        ManageDomainLoadingCell.self,
                                                        ManageDomainRecordCell.self,
                                                        CollectionViewShowHideCell.self,
                                                        DomainProfileSocialCell.self,
                                                        DomainProfileBadgeCell.self,
                                                        DomainProfileMetadataCell.self,
                                                        DomainProfileNoSocialsCell.self,
                                                        DomainProfileWeb3WebsiteCell.self,
                                                        DomainProfileWeb3WebsiteLoadingCell.self,
                                                        DomainProfileUpdatingRecordsCell.self] }
    var presenter: DomainProfileViewPresenterProtocol!
    var progress: Double? { presenter.progress }

    override var isObservingKeyboard: Bool { true }
    override var scrollableContentYOffset: CGFloat? { 8 }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var additionalAppearAnalyticParameters: Analytics.EventParameters { [.domainName: presenter.domainName] }
    override var navBackButtonConfiguration: CNavigationBarContentView.BackButtonConfiguration {
        .init(backArrowIcon: navBackStyle.icon,
              tintColor: .foregroundOnEmphasis,
              backTitleVisible: false,
              isEnabled: presenter.isNavEnabled())
    }
    override var navBarTitleAttributes: [NSAttributedString.Key : Any]? { [.foregroundColor : UIColor.foregroundOnEmphasis,
                                                                  .font: UIFont.currentFont(withSize: 16, weight: .semibold)] }
    let operationQueue = OperationQueue()
    private(set) var dataSource: DataSource!
    private var defaultBottomOffset: CGFloat { Constants.scrollableContentBottomOffset }
    private let minScrollYOffset: CGFloat = -40
    private var viewTitle: String? = nil
    var dashesProgressConfiguration: DashesProgressView.Configuration { .white(numberOfDashes: 3) }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.viewWillAppear()
        if let nav = self.navigationController {
            self.scrollingBehaviourFor(navigationController: nav)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        cNavigationController?.navigationBar.navBarContentView.setTitle(hidden: true, animated: false)
        presenter.viewDidAppear()
        if let nav = self.navigationController {
            self.scrollingBehaviourFor(navigationController: nav)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        navigationController?.navigationBar.scrollEdgeAppearance = .udAppearanceWith(backButtonColor: .foregroundOnEmphasis,
                                                                                     isTransparent: true)
    }
    
    override func shouldPopOnBackButton() -> Bool {
        presenter.shouldPopOnBackButton()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        setBottomContentInset()
    }
    
    override func keyboardWillHideAction(duration: Double, curve: Int) {
        setBottomContentInset()
    }
    
    override func customScrollingBehaviour(yOffset: CGFloat, in navBar: CNavigationBar) -> (()->())? {
        { [weak self, weak navBar] in
            guard let navBar = navBar else { return }
            
            self?.updateBlurVisibility(for: yOffset, in: navBar)
            self?.updateTitleVisibility(for: yOffset, in: navBar, limit: 134)
            self?.updatePassthroughState(for: yOffset, in: navBar, limit: 30)
        }
    }
}

// MARK: - DomainProfileViewProtocol
extension DomainProfileViewController: DomainProfileViewProtocol, DomainProfileSectionViewProtocol {
    func setConfirmButtonHidden(_ isHidden: Bool, style: DomainProfileViewController.ActionButtonStyle) {
        confirmButtonsContainerStack.isHidden = isHidden
        confirmButtonGradientView.isHidden = isHidden
        switch style {
        case .counter(let counter):
            confirmUpdateButton.isHidden = false
            confirmUpdateButton.setCounter(counter)
            confirmUpdateMainButton.isHidden = true
            confirmButtonsContainerStack.alignment = .center
            confirmButtonsContainerStackTopConstraint.constant = 0
        case .main(let type):
            confirmUpdateMainButton.isHidden = false
            confirmUpdateMainButton.setTitle(type.title, image: nil)
            confirmUpdateButton.isHidden = true
            confirmButtonsContainerStack.alignment = .fill
            confirmButtonsContainerStackTopConstraint.constant = 16
        }
        setBottomContentInset()
    }
    
    func set(title: String?) {
        self.viewTitle = title
        cNavigationController?.navigationBar.set(title: title)
    }
        
    func setAvailableActionsGroups(_ actionGroups: [DomainProfileActionsGroup]) {
        setupNavigation(actionGroups: actionGroups)
        cNavigationController?.updateNavigationBar()
    }
    
    func setBackgroundImage(_ image: UIImage?) {
        backgroundImageView.image = image
        backgroundImageBlurView.isHidden = image == nil
    }
}

// MARK: - UICollectionViewDelegate
extension DomainProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < minScrollYOffset {
            scrollView.contentOffset.y = minScrollYOffset
        }
        
        if let navigationController {
            scrollingBehaviourFor(navigationController: navigationController)
        }

        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
        for cell in collectionView.visibleCells {
            if let scrollListener = cell as? ScrollViewOffsetListener {
                scrollListener.didScrollTo(offset: scrollView.contentOffset)
            }
        }
    }
    
    private func scrollingBehaviourFor(navigationController: UINavigationController) {
        let yOffset = collectionView.contentOffset.y
        
        title = yOffset >= 134 ? viewTitle : nil
        navigationController.navigationBar.scrollEdgeAppearance = .udAppearanceWith(backButtonColor: .foregroundOnEmphasis,
                                                                                    isTransparent: yOffset <= 30)
        navigationController.navigationBar.standardAppearance = .udAppearanceWith(backButtonColor: .foregroundOnEmphasis,
                                                                                   isTransparent: false)
    }
}

// MARK: - Actions
private extension DomainProfileViewController {
    @IBAction func confirmChangesButtonPressed() {
        presenter.confirmChangesButtonPressed()
    }
    
    @objc func shareButtonPressed() {
        UDVibration.buttonTap.vibrate()
        logProfileButtonPressedAnalyticEvents(button: .share)
        presenter.shareButtonPressed()
    }
  
    @objc func didTapShowWalletDetailsButton() {
        logProfileButtonPressedAnalyticEvents(button: .showWalletDetails)
        UDVibration.buttonTap.vibrate()
        presenter.didTapShowWalletDetailsButton()
    }
    
    @objc func didTapViewInBrowserButton() {
        logProfileButtonPressedAnalyticEvents(button: .viewInBrowser) 
        UDVibration.buttonTap.vibrate()
        presenter.didTapViewInBrowserButton()
    }
    
    @objc func didTapSetReverseResolutionButton() {
        logProfileButtonPressedAnalyticEvents(button: .setReverseResolution)
        UDVibration.buttonTap.vibrate()
        presenter.didTapSetReverseResolutionButton()
    }
    
    @objc func didTapCopyDomainButton() {
        logProfileButtonPressedAnalyticEvents(button: .copyDomain)
        UDVibration.buttonTap.vibrate()
        presenter.didTapCopyDomainButton()
    }
    
    @objc func didTapAboutProfilesButton() {
        logProfileButtonPressedAnalyticEvents(button: .aboutProfile)
        UDVibration.buttonTap.vibrate()
        presenter.didTapAboutProfilesButton()
    }
    
    @objc func didTapMintedOnChainButton() {
        logProfileButtonPressedAnalyticEvents(button: .mintedOnChain)
        UDVibration.buttonTap.vibrate()
        presenter.didTapMintedOnChainButton()
    }
}

// MARK: - Private functions
private extension DomainProfileViewController {
    func setBottomContentInset() {
        var offset: CGFloat
        if confirmButtonGradientView.isHidden {
            offset = defaultBottomOffset
        } else {
            offset = (view.frame.height - confirmButtonGradientView.frame.minY) + defaultBottomOffset
        }
        if isKeyboardOpened {
            offset += keyboardFrame.height
        }
        if collectionView.contentInset.bottom != offset {
            collectionView.contentInset.bottom = offset
        }
    }
    
    func logProfileButtonPressedAnalyticEvents(button: Analytics.Button) {
        logButtonPressedAnalyticEvents(button: button)
    }
    
    @objc func closeButtonPressed() {
        UDVibration.buttonTap.vibrate()
        logButtonPressedAnalyticEvents(button: .close)
        dismiss(animated: true)
    }
}

// MARK: - Setup functions
private extension DomainProfileViewController {
    func setup() {
        view.backgroundColor = .brandUnstoppableBlue
        addProgressDashesView(configuration: dashesProgressConfiguration)
        setupNavigation(actionGroups: [])
        setupCollectionView()
        setupConfirmButton()
        setupGradientView()
        addHideKeyboardTapGesture(cancelsTouchesInView: false, toView: nil)
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
            if let nav = self.navigationController,
               self.cNavigationController == nil {
                self.dashesProgressView?.isHidden = true
                self.scrollingBehaviourFor(navigationController: nav)
                self.navigationItem.titleView = nil
            }
        }
    }
    
    func setupNavigation(actionGroups: [DomainProfileActionsGroup]) {
        if cNavigationController == nil {
            let closeButton = UIBarButtonItem(image: BaseViewController.NavBackIconStyle.cancel.icon,
                                              style: .plain,
                                              target: self,
                                              action: #selector(closeButtonPressed))
            closeButton.tintColor = .white
            navigationItem.leftBarButtonItem = closeButton
        }
        
        if actionGroups.isEmpty {
            navigationItem.rightBarButtonItems = nil
            return
        }
        // Share button
        let shareButton = UIButton()
        shareButton.tintColor = .foregroundOnEmphasis
        shareButton.setImage(.shareIcon, for: .normal)
        shareButton.addTarget(self, action: #selector(shareButtonPressed), for: .touchUpInside)
        let shareBarButtonItem = UIBarButtonItem(customView: shareButton)
        
        // More button
        let moreButton = UIButton()
        moreButton.tintColor = .foregroundOnEmphasis
        moreButton.setImage(.dotsCircleIcon, for: .normal)
        
        var children: [UIMenuElement] = []
        for group in actionGroups {
            let groupChildren = group.map({ self.uiAction(for: $0) })
            let menu = UIMenu(title: "", options: .displayInline, children: groupChildren)
            children.append(menu)
        }
        
        let menu = UIMenu(title: "", children: children)
        moreButton.showsMenuAsPrimaryAction = true
        moreButton.menu = menu
        moreButton.addAction(UIAction(handler: { [weak self] _ in
            self?.logButtonPressedAnalyticEvents(button: .dots)
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
        let moreBarButtonItem = UIBarButtonItem(customView: moreButton)

        // Assign
        navigationItem.rightBarButtonItems = [moreBarButtonItem, shareBarButtonItem]
    }
    
    func uiAction(for action: Action) -> UIAction {
        switch action {
        case .copyDomain:
            return UIAction(title: String.Constants.copyDomain.localized(),
                            image: .systemDocOnDoc,
                            identifier: .init(UUID().uuidString),
                            handler: { [weak self] _ in  self?.didTapCopyDomainButton() })
        case .viewWallet(let subtitle):
            return UIAction.createWith(title: String.Constants.viewWallet.localized(presenter.walletName.lowercased()),
                                       subtitle: subtitle,
                                       image: .arrowUpRight,
                                       handler: { [weak self] _ in  self?.didTapShowWalletDetailsButton() })
        case .viewInBrowser:
            return UIAction.createWith(title: String.Constants.viewInBrowser.localized(),
                                       image: .systemGlobe,
                                       handler: { [weak self] _ in  self?.didTapViewInBrowserButton() })
        case .setReverseResolution(let isEnabled):
            return UIAction.createWith(title: String.Constants.setReverseResolution.localized(),
                                       subtitle: isEnabled ? nil : String.Constants.reverseResolutionUnavailableWhileRecordsUpdating.localized(),
                                       image: .arrowRightArrowLeft,
                                       attributes: isEnabled ? [] : [.disabled],
                                       handler: { [weak self] _ in  self?.didTapSetReverseResolutionButton() })
        case .aboutProfiles:
            return UIAction(title: String.Constants.learnMore.localized(),
                            image: .systemQuestionmarkCircle,
                            identifier: .init(UUID().uuidString),
                            handler: { [weak self] _ in  self?.didTapAboutProfilesButton() })
            
        case .mintedOn(let chain):
            return UIAction(title: chain.fullName,
                            image: chain.icon,
                            identifier: .init(UUID().uuidString),
                            handler: { [weak self] _ in  self?.didTapMintedOnChainButton() })
        }
    }
    
    func setupConfirmButton() {
        confirmUpdateButton.setTitle(String.Constants.confirmUpdates.localized())
        confirmUpdateButton.counterLimit = 9
    }
    
    func setupGradientView() {
        let gradientColor = #colorLiteral(red: 0.07843137255, green: 0.07843137255, blue: 0.08235294118, alpha: 1)
        confirmButtonGradientView.gradientColors = [gradientColor.withAlphaComponent(0.01), gradientColor]
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.register(DomainProfileSectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: DomainProfileSectionHeader.reuseIdentifier)
        collectionView.register(CollectionDashesHeaderReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: CollectionDashesHeaderReusableView.reuseIdentifier)
        collectionView.register(CollectionTextFooterReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CollectionTextFooterReusableView.reuseIdentifier)

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = DomainProfileDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .topInfo(let data):
                let cell = collectionView.dequeueCellOfType(DomainProfileTopInfoCell.self, forIndexPath: indexPath)
                cell.set(with: data)
                
                return cell
            case .updatingRecords(let displayInfo):
                let cell = collectionView.dequeueCellOfType(DomainProfileUpdatingRecordsCell.self, forIndexPath: indexPath)
                cell.setWith(displayInfo: displayInfo)
                
                return cell
            case .generalInfo(let displayInfo):
                let cell = collectionView.dequeueCellOfType(DomainProfileGeneralInfoCell.self, forIndexPath: indexPath)
                cell.setWith(displayInfo: displayInfo)
                
                return cell
            case .loading(_, let style, let uiConfiguration):
                let cell = collectionView.dequeueCellOfType(ManageDomainLoadingCell.self, forIndexPath: indexPath)
                
                cell.set(style: style)
                cell.set(uiConfiguration: uiConfiguration)
                cell.setBlinkingColor(.white.withAlphaComponent(0.08))
                
                return cell
            case .record(let displayInfo):
                let cell = collectionView.dequeueCellOfType(ManageDomainRecordCell.self, forIndexPath: indexPath)
                cell.setWith(displayInfo: displayInfo)
                
                return cell
            case .social(let displayInfo):
                let cell = collectionView.dequeueCellOfType(DomainProfileSocialCell.self, forIndexPath: indexPath)
                cell.setWith(displayInfo: displayInfo)
                
                return cell
            case .noSocials(let displayInfo):
                let cell = collectionView.dequeueCellOfType(DomainProfileNoSocialsCell.self, forIndexPath: indexPath)
                cell.setWith(displayInfo: displayInfo)

                return cell
            case .badge(let displayInfo):
                let cell = collectionView.dequeueCellOfType(DomainProfileBadgeCell.self, forIndexPath: indexPath)
                cell.setWith(displayInfo: displayInfo)
                
                return cell
            case .web3Website(let displayInfo):
                let cell = collectionView.dequeueCellOfType(DomainProfileWeb3WebsiteCell.self, forIndexPath: indexPath)
                cell.setWith(displayInfo: displayInfo)
                
                return cell
            case .web3WebsiteLoading:
                let cell = collectionView.dequeueCellOfType(DomainProfileWeb3WebsiteLoadingCell.self, forIndexPath: indexPath)
                
                return cell
            case .metadata(let displayInfo):
                let cell = collectionView.dequeueCellOfType(DomainProfileMetadataCell.self, forIndexPath: indexPath)
                cell.setWith(displayInfo: displayInfo)
                
                return cell
            case .showAll:
                let cell = collectionView.dequeueCellOfType(CollectionViewShowHideCell.self, forIndexPath: indexPath)
                
                cell.setWith(text: String.Constants.showAll.localized(),
                             direction: .down,
                             style: .clear,
                             height: 56)
                
                return cell
            case .hide:
                let cell = collectionView.dequeueCellOfType(CollectionViewShowHideCell.self, forIndexPath: indexPath)
                
                cell.setWith(text: String.Constants.hide.localized(),
                             direction: .up,
                             style: .clear,
                             height: 56)
                
                return cell
            }
        })
        
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            let section = self?.section(at: indexPath)
            
            if elementKind == UICollectionView.elementKindSectionHeader {
                switch section {
                case .topInfo, .updatingRecords, .none, .showHideItem, .footer:
                    return nil
                case .records(let description), .socials(let description), .noSocials(let description), .badges(let description), .profileMetadata(let description), .web3Website(let description):
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                               withReuseIdentifier: DomainProfileSectionHeader.reuseIdentifier,
                                                                               for: indexPath) as! DomainProfileSectionHeader
                    view.setWith(description: description)
                    return view
                case .generalInfo, .dashesSeparator:
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                               withReuseIdentifier: CollectionDashesHeaderReusableView.reuseIdentifier,
                                                                               for: indexPath) as! CollectionDashesHeaderReusableView
                    view.setDashesConfiguration(.domainProfile)
                    if case .generalInfo = section {
                        view.setAlignmentPosition(.top)
                    } else {
                        view.setAlignmentPosition(.bottom)
                    }
                    
                    return view
                }
            } else {
                switch section {
                case .footer(let footer):
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                               withReuseIdentifier: CollectionTextFooterReusableView.reuseIdentifier,
                                                                               for: indexPath) as! CollectionTextFooterReusableView
                    view.setFooter(footer, textColor: .white.withAlphaComponent(0.56))
                    return view
                default:
                    return nil
                }
            }
        }
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 8
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))
            var layoutSection: NSCollectionLayoutSection = .flexibleListItemSection()
            let layoutSectionInset = NSDirectionalEdgeInsets(top: 1,
                                                             leading: spacing + 1,
                                                             bottom: 1,
                                                             trailing: spacing + 1)
            @MainActor
            func addBackgroundWithTopInset(_ topInset: CGFloat, bottomInset: CGFloat? = nil) {
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackgroundWhiteWithAlpha.reuseIdentifier)
                background.contentInsets.top = topInset
                if let bottomInset {
                    background.contentInsets.bottom = bottomInset
                }
                layoutSection.decorationItems = [background]
            }
            @MainActor
            func addHeader() {
                let headerHeight = section?.headerHeight ?? 0
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(headerHeight))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems.append(header)
            }
            @MainActor
            func setSectionContentInset() {
                layoutSection.contentInsets = layoutSectionInset
            }
            @MainActor
            func addFooter(_ footer: String) {
                let footerHeight: CGFloat = footer.height(withConstrainedWidth: UIScreen.main.bounds.width - (spacing * 2),
                                                          font: CollectionTextFooterReusableView.font,
                                                          lineHeight: 20)
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(footerHeight + 12))
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionFooter,
                                                                         alignment: .bottom)
                layoutSection.boundarySupplementaryItems.append(footer)
            }
            
            switch section {
            case .topInfo:
                Void()
            case .dashesSeparator:
                setSectionContentInset()
                addHeader()
            case .updatingRecords:
                setSectionContentInset()
                addBackgroundWithTopInset(0, bottomInset: 16)
            case .showHideItem:
                setSectionContentInset()
                addBackgroundWithTopInset(0)
            case .records, .socials, .generalInfo, .profileMetadata, .web3Website:
                setSectionContentInset()
                
                let headerHeight = section?.headerHeight ?? 0
                if headerHeight > 0 {
                    addHeader()
                }
                
                addBackgroundWithTopInset(headerHeight)
            case .noSocials:
                setSectionContentInset()
                addHeader()
            case .badges:
                let badgeSize: CGFloat = 64
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(badgeSize),
                                                                                     heightDimension: .absolute(badgeSize)))
                let numberOfItems = DomainProfileBadgesSection.numberOfBadgesInTheRow()
                let containerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                           heightDimension: .absolute(badgeSize)),
                                                                        subitem: item, count: numberOfItems)
                let containerWidth = layoutEnvironment.container.contentSize.width
                let horizontalInset = layoutSectionInset.leading + layoutSectionInset.trailing
                let groupWidth = containerWidth - horizontalInset
                let groupFreeSpacing = groupWidth - (badgeSize * CGFloat(numberOfItems))
                let groupItemSpacing = groupFreeSpacing / CGFloat(numberOfItems - 1)
                containerGroup.interItemSpacing = .fixed(groupItemSpacing)
                
                layoutSection = NSCollectionLayoutSection(group: containerGroup)
                layoutSection.interGroupSpacing = 8
                
                setSectionContentInset()
                
                addHeader()
            case .footer(let footer):
                setSectionContentInset()
                addFooter(footer)
            case .none:
                Void()
            }
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackgroundWhiteWithAlpha.self, forDecorationViewOfKind: CollectionReusableRoundedBackgroundWhiteWithAlpha.reuseIdentifier)
        
        return layout
    }
    
    func section(at indexPath: IndexPath) -> Section? {
        self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
    }
}

// MARK: - Collection elements
extension DomainProfileViewController {
    enum Section: Hashable, Sendable {
        case topInfo
        case generalInfo
        case updatingRecords
        case socials(headerDescription: DomainProfileSectionHeader.HeaderDescription), noSocials(headerDescription: DomainProfileSectionHeader.HeaderDescription)
        case records(headerDescription: DomainProfileSectionHeader.HeaderDescription)
        case badges(headerDescription: DomainProfileSectionHeader.HeaderDescription)
        case profileMetadata(headerDescription: DomainProfileSectionHeader.HeaderDescription)
        case web3Website(headerDescription: DomainProfileSectionHeader.HeaderDescription)
        case showHideItem(id: UUID = .init())
        case dashesSeparator(id: UUID = .init())
        case footer(_ footer: String)
        
        var headerHeight: CGFloat {
            switch self {
            case .topInfo, .showHideItem, .updatingRecords, .footer: return 0
            case .generalInfo: return CollectionDashesHeaderReusableView.Height
            case .dashesSeparator: return 19
            case .records, .socials, .noSocials, .badges, .profileMetadata, .web3Website: return DomainProfileSectionHeader.Height
            }
        }
    }
    
    enum Item: Hashable, Sendable {
        case topInfo(data: ItemTopInfoData)
        case updatingRecords(displayInfo: DomainProfileUpdatingRecordsDisplayInfo)
        case generalInfo(displayInfo: DomainProfileGeneralDisplayInfo)
        case loading(id: UUID = .init(),
                     style: ManageDomainLoadingCell.Style = .default,
                     uiConfiguration: ManageDomainLoadingCell.UIConfiguration = .default)
        case social(displayInfo: DomainProfileSocialsDisplayInfo)
        case noSocials(displayInfo: DomainProfileSocialsEmptyDisplayInfo)
        case record(displayInfo: ManageDomainRecordDisplayInfo)
        case badge(displayInfo: DomainProfileBadgeDisplayInfo)
        case web3Website(displayInfo: DomainProfileWeb3WebsiteDisplayInfo), web3WebsiteLoading(id: UUID = .init())
        case metadata(displayInfo: DomainProfileMetadataDisplayInfo)
        case showAll(section: Section), hide(section: Section)
    }
    
    enum State: Hashable {
        case loading, `default`, updatingRecords, loadingError, updatingProfile(dataType: UpdateProfileDataType)
        
        enum UpdateProfileDataType: Hashable {
            case onChain, offChain, mixed
        }
    }
}

extension DomainProfileViewController {
    enum Action: Hashable {
        case copyDomain, viewWallet(subtitle: String), viewInBrowser, setReverseResolution(isEnabled: Bool)
        case aboutProfiles, mintedOn(chain: BlockchainType)
    }
    
    enum ActionButtonStyle {
        case counter(Int)
        case main(MainButtonType)
        
        enum MainButtonType {
            case skip, confirm
            
            var title: String {
                switch self {
                case .skip:
                    return String.Constants.skip.localized()
                case .confirm:
                    return String.Constants.confirm.localized()
                }
            }
        }
    }
}

import SwiftUI
struct DomainProfileViewControllerWrapper: UIViewControllerRepresentable {
    
    let domain: DomainDisplayInfo
    let wallet: WalletEntity
    let preRequestedAction: PreRequestedProfileAction?
    let sourceScreen: DomainProfileViewPresenter.SourceScreen
    let tabRouter: HomeTabRouter
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UDRouter().buildDomainProfileModule(domain: domain,
                                                     wallet: wallet,
                                                     preRequestedAction: preRequestedAction,
                                                     sourceScreen: sourceScreen, 
                                                     tabRouter: tabRouter)
        let nav = ProfileNavController(rootViewController: vc)
        nav.isModalInPresentation = true

        return nav
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
    final class ProfileNavController: UINavigationController {
        override var traitCollection: UITraitCollection {
            UITraitCollection(traitsFrom: [super.traitCollection, UITraitCollection(userInterfaceStyle: .dark)])
        }
    }
    
}

#Preview {
    
    struct PreviewContainer: View {
        
        @State private var isPresenting = false
        
        let wallet: WalletEntity
        let domain: DomainDisplayInfo
        
        var body: some View {
            ProgressView()
                .sheet(isPresented: $isPresenting) {
                   DomainProfileViewControllerWrapper(domain: domain,
                                                      wallet: wallet,
                                                      preRequestedAction: nil,
                                                      sourceScreen: .domainsCollection,
                                                      tabRouter: MockEntitiesFabric.Home.createHomeTabRouter())
                }
                .onAppear {
                    isPresenting = true
                }
        }
        
    }
    
    let wallet = MockEntitiesFabric.Wallet.mockEntities()[0]
    let domain = wallet.domains.first!
    
    return PreviewContainer(wallet: wallet,
                            domain: domain)
    
}

