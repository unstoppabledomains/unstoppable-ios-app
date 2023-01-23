//
//  SignTransactionDomainSelectionViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import UIKit

@MainActor
protocol SignTransactionDomainSelectionViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: SignTransactionDomainSelectionSnapshot, animated: Bool)
    func setSubhead(hidden: Bool)
}

typealias SignTransactionDomainSelectionDataSource = UICollectionViewDiffableDataSource<SignTransactionDomainSelectionViewController.Section, SignTransactionDomainSelectionViewController.Item>
typealias SignTransactionDomainSelectionSnapshot = NSDiffableDataSourceSnapshot<SignTransactionDomainSelectionViewController.Section, SignTransactionDomainSelectionViewController.Item>

@MainActor
final class SignTransactionDomainSelectionViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet private weak var titleContainerView: UIStackView!
    @IBOutlet private var titleView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dismissButton: UIButton!
    @IBOutlet private weak var searchButton: UIButton!
    @IBOutlet private var searchContainer: UIView!
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var subheadStackView: UIStackView!
    @IBOutlet private weak var subheadWhatIsButton: SubheadTertiaryButton!
    @IBOutlet private weak var subheadMeanButton: SubheadTertiaryButton!
    
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [DomainSelectionCell.self,
                                                        DomainsCollectionSearchEmptyCell.self,
                                                        CollectionViewShowHideCell.self] }
    var presenter: SignTransactionDomainSelectionViewPresenterProtocol!
    private var dataSource: SignTransactionDomainSelectionDataSource!
    private var defaultBottomOffset: CGFloat { Constants.scrollableContentBottomOffset }
  
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var isObservingKeyboard: Bool { true }
    override var analyticsName: Analytics.ViewName { .signWCTransactionDomainSelection }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        collectionView.contentInset.bottom = keyboardHeight + defaultBottomOffset
    }
    
    override func keyboardWillHideAction(duration: Double, curve: Int) {
        collectionView.contentInset.bottom = defaultBottomOffset
    }
}

// MARK: - SignTransactionDomainSelectionViewProtocol
extension SignTransactionDomainSelectionViewController: SignTransactionDomainSelectionViewProtocol {
    func applySnapshot(_ snapshot: SignTransactionDomainSelectionSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    func setSubhead(hidden: Bool) {
        subheadStackView.isHidden = hidden
    }
}

// MARK: - UICollectionViewDelegate
extension SignTransactionDomainSelectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
}

// MARK: - UISearchBarDelegate
extension SignTransactionDomainSelectionViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        logAnalytic(event: .didStartSearching)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        logAnalytic(event: .didSearch, parameters: [.domainName : searchText])
        presenter.didSearchWith(key: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        logAnalytic(event: .didStopSearching)
        UDVibration.buttonTap.vibrate()
        searchBar.text = ""
        presenter.didSearchWith(key: "")
        setSearchBarActive(false)
        presenter.didStopSearch()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        logAnalytic(event: .didStopSearching)
        setSearchBarActive(false)
        presenter.didStopSearch()
    }
}

// MARK: - Private functions
private extension SignTransactionDomainSelectionViewController {
    func setSearchBarActive(_ isActive: Bool) {
        if isActive {
            searchContainer.removeFromSuperview()
            titleContainerView.addArrangedSubview(searchContainer)
        }
        UIView.animate(withDuration: 0.0) { [weak self] in
            self?.titleView.arrangedSubviews.forEach({ view in
                view.isHidden = isActive
            })
                        self?.titleView.isHidden = isActive
            self?.searchBar.superview?.isHidden = !isActive
        }
        if isActive {
            searchBar.becomeFirstResponder()
        } else {
            searchBar.resignFirstResponder()
        }
    }
    
    @IBAction func searchButtonPressed() {
        UDVibration.buttonTap.vibrate()
        setSearchBarActive(true)
        presenter.didStartSearch()
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .close)
        UDVibration.buttonTap.vibrate()
        dismiss(animated: true)
    }
    
    @IBAction func subheadButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .whatDoesReverseResolutionMean)
        UDVibration.buttonTap.vibrate()
        presenter.subheadButtonPressed()
    }
}

// MARK: - Setup functions
private extension SignTransactionDomainSelectionViewController {
    func setup() {
        setupCollectionView()
        navigationController?.navigationBar.isHidden = true
        localizeContent()
        setupSearchBar()
    }
    
    func localizeContent() {
        titleLabel.setAttributedTextWith(text: String.Constants.selectNFTDomainTitle.localized(),
                                         font: .currentFont(withSize: 16, weight: .semibold),
                                         textColor: .foregroundDefault)
        dismissButton.setTitle("", for: .normal)
        searchButton.setTitle("", for: .normal)
        subheadWhatIsButton.setTitle(String.Constants.whatDoesResolutionMeanWhat.localized(), image: nil)
        subheadMeanButton.setTitle(String.Constants.whatDoesResolutionMeanMean.localized(), image: .reverseResolutionArrows12)
    }
    
    func setupSearchBar() {
        searchBar.applyUDStyle()
        searchBar.delegate = self
        searchBar.setShowsCancelButton(true, animated: false)
        searchBar.setNeedsLayout()
        searchBar.layoutIfNeeded()
        searchBar.searchTextField.textContentType = .oneTimeCode
        searchBar.searchTextField.spellCheckingType = .no
        setSearchBarActive(false)
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 32
        collectionView.register(SignTransactionDomainSelectionSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: SignTransactionDomainSelectionSectionHeaderView.reuseIdentifier)
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = SignTransactionDomainSelectionDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .domain(let domain, let isSelected, let isReverseResolutionSet):
                let cell = collectionView.dequeueCellOfType(DomainSelectionCell.self, forIndexPath: indexPath)
                
                cell.setWith(domain: domain,
                             isSelected: isSelected,
                             indicator: isReverseResolutionSet ? .reverseResolution : nil)
                
                return cell
            case .emptyState:
                let cell = collectionView.dequeueCellOfType(DomainsCollectionSearchEmptyCell.self, forIndexPath: indexPath)
                cell.setCenterYOffset(-40)
                
                return cell
            case .showOthers(let domainsCount, _):
                let cell = collectionView.dequeueCellOfType(CollectionViewShowHideCell.self, forIndexPath: indexPath)
                
                cell.setWith(text: String.Constants.showNMore.localized(domainsCount),
                             direction: .down,
                             height: 70)
                
                return cell
            case .hide:
                let cell = collectionView.dequeueCellOfType(CollectionViewShowHideCell.self, forIndexPath: indexPath)
                
                cell.setWith(text: String.Constants.hide.localized(),
                             direction: .up,
                             height: 70)
                
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            guard let section = self?.section(at: indexPath) else { return nil }
            
            switch section {
            case .walletDomains(let walletName, let balance):
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                           withReuseIdentifier: SignTransactionDomainSelectionSectionHeaderView.reuseIdentifier,
                                                                           for: indexPath) as! SignTransactionDomainSelectionSectionHeaderView
                view.setHeader(for: walletName, balance: balance)
                return view
            case .selectedDomain, .emptyState:
                return nil
            }
        }
    }
    
    func section(at indexPath: IndexPath) -> Section? {
        self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))
            let layoutSection: NSCollectionLayoutSection
            
            layoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            
            switch section {
            case .walletDomains:
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(section?.headerHeight ?? 0))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
            case .emptyState:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                     heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = .zero
                
                let containerGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .fractionalHeight(1)),
                    subitems: [item])
                let section = NSCollectionLayoutSection(group: containerGroup)
                section.contentInsets = .zero
                section.contentInsets.bottom = -368 // Keyboard height inset
                
                return section
            default:
                Void()
            }
            
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            background.contentInsets.top = section?.headerHeight ?? 0
            layoutSection.decorationItems = [background]
            
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension SignTransactionDomainSelectionViewController {
    enum Section: Hashable {
        case selectedDomain, walletDomains(walletName: String, balance: WalletBalance?), emptyState
        
        var headerHeight: CGFloat {
            switch self {
            case .walletDomains:
                return SignTransactionDomainSelectionSectionHeaderView.Height
            case .selectedDomain, .emptyState:
                return 0
            }
        }
    }
    
    enum Item: Hashable {
        case domain(_ domain: DomainItem, isSelected: Bool, isReverseResolutionSet: Bool)
        case emptyState
        case showOthers(domainsCount: Int, walletAddress: HexAddress)
        case hide(walletAddress: HexAddress)
    }
}
