//
//  ChatMessageReactionsSelectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.02.2024.
//

import UIKit

final class ChatMessageReactionsSelectionView: UIView {
    
    private var collectionView: UICollectionView!
    private let reactions = MessagingReactionType.allCases
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
}

// MARK: - Setup methods
private extension ChatMessageReactionsSelectionView {
    func setup() {
        setupBackground()
        setupCollectionView()
        alpha = 0
        UIView.animate(withDuration: 0.25, delay: 0.6) {
            self.alpha = 1
        }
    }
    
    func setupBackground() {
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        backgroundView.frame = bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.layer.cornerRadius = 10
        backgroundView.clipsToBounds = true
        addSubview(backgroundView)
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        addSubview(collectionView)
        collectionView.registerCellNibOfType(ChatMessageReactionsSelectionViewCell.self)
        collectionView.dataSource = self 
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
    }
}

// MARK: - UICollectionViewDataSource
extension ChatMessageReactionsSelectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        reactions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCellOfType(ChatMessageReactionsSelectionViewCell.self, forIndexPath: indexPath)
        cell.setReaction(reactions[indexPath.row])
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ChatMessageReactionsSelectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let reaction = reactions[indexPath.row]
        print("Did select reaction \(reaction.rawValue)")
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ChatMessageReactionsSelectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        .square(size: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        4
    }
}
