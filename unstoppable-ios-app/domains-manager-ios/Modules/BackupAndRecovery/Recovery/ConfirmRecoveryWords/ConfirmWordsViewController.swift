//
//  ConfirmWordsViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.03.2022.
//

import UIKit

protocol ConfirmWordsViewControllerProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    func setMnems(original mnemonicsOriginal: [String], sorted mnemonicsSorted: [String], confirmation mnemonicsConfirmation: [String])
}

final class ConfirmWordsViewController: BaseViewController {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var forgotWordsButton: SecondaryButton!
    @IBOutlet private weak var wordsCollectionView: UICollectionView!
    @IBOutlet private weak var confirmWordCollectionView: UICollectionView!

    private var mnemonicsOriginal: [String] = []
    private var mnemonicsSorted: [String] = []
    private var mnemonicsConfirmation: [String] = []
    private var count = 0
    var presenter: ConfirmWordsPresenterProtocol!
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    
    static func instantiate() -> ConfirmWordsViewController {
        ConfirmWordsViewController.nibInstance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        presenter.viewDidLoad()
    }
}

// MARK: - ConfirmWordsViewController
extension ConfirmWordsViewController: ConfirmWordsViewControllerProtocol {
    var progress: Double? { presenter.progress }
    
    func setMnems(original mnemonicsOriginal: [String], sorted mnemonicsSorted: [String], confirmation mnemonicsConfirmation: [String]) {
        self.mnemonicsOriginal = mnemonicsOriginal
        self.mnemonicsSorted = mnemonicsSorted
        self.mnemonicsConfirmation = mnemonicsConfirmation
        
        wordsCollectionView.reloadData()
        confirmWordCollectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension ConfirmWordsViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == wordsCollectionView {
            return 1
        }
        return mnemonicsConfirmation.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == wordsCollectionView {
            return mnemonicsSorted.count
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == wordsCollectionView {
            let cell = collectionView.dequeueCellOfType(ConfirmWordListCell.self, forIndexPath: indexPath)
            let word = mnemonicsSorted[indexPath.row]
            cell.setWord(word)
            
            return cell
        } else {
            let cell = collectionView.dequeueCellOfType(ConfirmWordConfirmationCell.self, forIndexPath: indexPath)
            let word = mnemonicsConfirmation[indexPath.section]
            let number = presenter.indices[indexPath.section] + 1
            cell.setWord(word, number: number)
            cell.accessibilityIdentifier = "Confirm Recovery Words Confirm Cell \(word)"
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ConfirmWordsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let wordListCell = collectionView.cellForItem(at: indexPath) as? ConfirmWordListCell else { return }
        
        let selectedWord = mnemonicsSorted[indexPath.row]
        let confirmationWord = mnemonicsConfirmation[count]
        
        if selectedWord == confirmationWord {
            logButtonPressedAnalyticEvents(button: .correctWord)
            Vibration.success.vibrate()

            wordListCell.blinkState(.success)
            if let cell = confirmWordCollectionView.cellForItem(at: IndexPath(item: 0, section: count)) as? ConfirmWordConfirmationCell {
                cell.setGuessed()
            }
            
            count += 1
            if count == mnemonicsConfirmation.count {
                presenter.didConfirmWords()
                return
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.showNextWord()
                }
            }
        } else {
            logButtonPressedAnalyticEvents(button: .incorrectWord)
            Vibration.error.vibrate()
            wordListCell.blinkState(.error)
        }
    }
}

// MARK: - Private methods
private extension ConfirmWordsViewController {
    @IBAction func forgotPasswordButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .forgotPassword)
        cNavigationController?.popViewController(animated: true)
    }
    
    func showNextWord() {
        if let cell = confirmWordCollectionView.cellForItem(at: IndexPath(row: 0, section: count)) {
            var offset = cell.frame.origin
            offset.x -= 16
            offset.y = confirmWordCollectionView.contentOffset.y
            confirmWordCollectionView.setContentOffset(offset, animated: true)
        }
        setSubtitle()
    }
    
    func setSubtitle() {
        guard count < presenter.indices.count else { return }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        
        let index = presenter.indices[count]
        let number = formatter.string(from: (index + 1) as NSNumber) ?? ""
        
        let subtitle = String.Constants.whichWordBelow.localized(number)
        let highlightedSubtitle = String.Constants.whichWordBelowHighlighted.localized(number)
        
        subtitleLabel.setSubtitle(subtitle)
        let fontSize = subtitleLabel.font.pointSize
        subtitleLabel.updateAttributesOf(text: highlightedSubtitle,
                                         withFont: .currentFont(withSize: fontSize, weight: .medium),
                                         textColor: .foregroundDefault)
    }
}

// MARK: - Setup methods
private extension ConfirmWordsViewController {
    func setup() {
        addProgressDashesView()
        localiseContent()
        setupCollectionViews()
        
        forgotWordsButton.accessibilityIdentifier = "Confirm Recovery Words Forgot Button"
        confirmWordCollectionView.accessibilityValue = "Confirm Recovery Words Confirm Collection View"
    }
    
    func localiseContent() {
        titleLabel.setTitle(String.Constants.confirmYourWords.localized())
        forgotWordsButton.setTitle(String.Constants.iForgotMyWords.localized(), image: nil)
        setSubtitle()
    }
  
    func createConfirmationWordsLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        let indices = presenter.indices
        let spacing: CGFloat = 16
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = .zero
            
            // Last row should fill whole width
            let isLastSection = sectionIndex == (indices.count - 1)
            let widthDimension: NSCollectionLayoutDimension = isLastSection ? .absolute(layoutEnvironment.container.contentSize.width - (spacing * 2)) : .fractionalWidth(0.855)
            let containerGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: widthDimension,
                                                   heightDimension: .fractionalHeight(1)),
                subitems: [item])
            let section = NSCollectionLayoutSection(group: containerGroup)
            section.orthogonalScrollingBehavior = .groupPaging
            section.contentInsets = .init(top: 0, leading: spacing, bottom: 0, trailing: 0)
            
            return section
            
        }, configuration: config)
        return layout
    }
    
    func createWordsCollectionLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(48))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
        let spacing = CGFloat(16)
        group.interItemSpacing = .fixed(spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = .zero
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    func setupCollectionViews() {
        wordsCollectionView.delegate = self
        wordsCollectionView.dataSource = self
        wordsCollectionView.collectionViewLayout = createWordsCollectionLayout()
        wordsCollectionView.backgroundColor = .clear
        wordsCollectionView.registerCellNibOfType(ConfirmWordListCell.self)
        
        confirmWordCollectionView.delegate = self
        confirmWordCollectionView.dataSource = self
        confirmWordCollectionView.collectionViewLayout = createConfirmationWordsLayout()
        confirmWordCollectionView.backgroundColor = .clear
        confirmWordCollectionView.isUserInteractionEnabled = false
        confirmWordCollectionView.registerCellNibOfType(ConfirmWordConfirmationCell.self)
    }
}
