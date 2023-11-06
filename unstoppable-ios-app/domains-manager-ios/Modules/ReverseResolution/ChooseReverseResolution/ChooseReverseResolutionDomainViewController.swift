//
//  ChooseReverseResolutionViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.09.2022.
//

import UIKit

@MainActor
protocol ChooseReverseResolutionDomainViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: ChooseReverseResolutionDomainSnapshot, animated: Bool)
    func setConfirmButton(enabled: Bool)
}

typealias ChooseReverseResolutionDomainDataSource = UICollectionViewDiffableDataSource<ChooseReverseResolutionDomainViewController.Section, ChooseReverseResolutionDomainViewController.Item>
typealias ChooseReverseResolutionDomainSnapshot = NSDiffableDataSourceSnapshot<ChooseReverseResolutionDomainViewController.Section, ChooseReverseResolutionDomainViewController.Item>

@MainActor
final class ChooseReverseResolutionDomainViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var confirmButton: MainButton!
    var cellIdentifiers: [UICollectionViewCell.Type] { [ChooseReverseResolutionCollectionCell.self, CollectionViewHeaderCell.self] }
    var presenter: ChooseReverseResolutionDomainViewPresenterProtocol!
    override var prefersLargeTitles: Bool { true }
    override var largeTitleIcon: UIImage? { .chooseRRDomainIllustration }
    override var largeTitleAlignment: NSTextAlignment { .center }
    override var largeTitleIconSize: CGSize? { CGSize(width: 80, height: 80) }
    override var scrollableContentYOffset: CGFloat? { 10 }
    override var navBackStyle: BaseViewController.NavBackIconStyle { presenter.navBackStyle }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }

    private var dataSource: ChooseReverseResolutionDomainDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
}

// MARK: - ChooseReverseResolutionViewProtocol
extension ChooseReverseResolutionDomainViewController: ChooseReverseResolutionDomainViewProtocol {
    func applySnapshot(_ snapshot: ChooseReverseResolutionDomainSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    func setConfirmButton(enabled: Bool) {
        confirmButton.isEnabled = enabled
    }
}

// MARK: - UICollectionViewDelegate
extension ChooseReverseResolutionDomainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - Private functions
private extension ChooseReverseResolutionDomainViewController {
    @IBAction func confirmButtonPressed(_ sender: Any) {
        presenter.confirmButtonPressed()
    }
}

// MARK: - Setup functions
private extension ChooseReverseResolutionDomainViewController {
    func setup() {
        setupCollectionView()
        setupConfirmButton()
        self.title = presenter.title
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 254

        configureDataSource()
    }
    
    func setupConfirmButton() {
        var icon: UIImage?
        if User.instance.getSettings().touchIdActivated {
            icon = appContext.authentificationService.biometricIcon
        }
        confirmButton.setTitle(String.Constants.confirm.localized(), image: icon)
    }
    
    func configureDataSource() {
        dataSource = ChooseReverseResolutionDomainDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .domain(let details):
                let cell = collectionView.dequeueCellOfType(ChooseReverseResolutionCollectionCell.self, forIndexPath: indexPath)
                
                cell.setWith(domain: details.domain,
                             isSelected: details.isSelected,
                             isCurrent: details.isCurrent)
                
                return cell
            case .header(let subtitle):
                let cell = collectionView.dequeueCellOfType(CollectionViewHeaderCell.self, forIndexPath: indexPath)
                cell.setTitle(nil,
                              subtitleDescription: subtitle,
                              icon: nil)
                return cell
            }
        })
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
            
            let layoutSection: NSCollectionLayoutSection
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))

            layoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            
            switch section {
            case .main:
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                layoutSection.decorationItems = [background]
            case .header, .none:
                Void()
            }
            
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension ChooseReverseResolutionDomainViewController {
    enum Section: Hashable {
        case header, main(_ val: Int)
    }
    
    enum Item: Hashable {
        case domain(details: DomainDetails), header(subtitle: CollectionViewHeaderCell.SubtitleDescription)
    }
    
    struct DomainDetails: Hashable {
        let domain: DomainDisplayInfo
        let isSelected: Bool
        var isCurrent: Bool = false
    }
}

