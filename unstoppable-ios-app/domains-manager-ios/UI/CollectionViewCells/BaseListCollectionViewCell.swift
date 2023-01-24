//
//  BaseListCollectionViewCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit

class BaseListCollectionViewCell: UICollectionViewCell {
    
    static let height: CGFloat = TableViewSelectionCell.Height

    @IBOutlet private(set) weak var containerView: UIView!
    
    var isSelectable: Bool = true
    var containerColor: UIColor { .backgroundOverlay }
    var backgroundContainerColor: UIColor { containerColor }
    private var backgroundContainerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        containerView.layer.cornerRadius = 12
        containerView.backgroundColor = containerColor
        addBackgroundContainerView()
    }
    
    override var isHighlighted: Bool {
        didSet {
            guard isSelectable else { return }
            
            setBackgroundFor(highlighted: isHighlighted)
        }
    }
    
    func updateAppearance() {
        containerView.backgroundColor = containerColor
        backgroundContainerView.backgroundColor = backgroundContainerColor
    }
    
    func blink(for seconds: TimeInterval) {
        setBackgroundFor(highlighted: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.setBackgroundFor(highlighted: false)
        }
    }
}

// MARK: - Private methods
private extension BaseListCollectionViewCell {
    func addBackgroundContainerView() {
        backgroundContainerView = UIView()
        backgroundContainerView.backgroundColor = backgroundContainerColor
        backgroundContainerView.embedInSuperView(self, constraints: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
        backgroundContainerView.layer.cornerRadius = 8
        containerView.insertSubview(backgroundContainerView, at: 0)
    }
    
    func setBackgroundFor(highlighted: Bool) {
        backgroundContainerView.backgroundColor = highlighted ? .backgroundSubtle : backgroundContainerColor
    }
}
