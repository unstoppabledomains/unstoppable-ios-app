//
//  ConfirmWordConfirmationCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.04.2022.
//

import UIKit

final class ConfirmWordConfirmationCell: UICollectionViewCell {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var wordLabel: UILabel!
    @IBOutlet private weak var numberLabel: UILabel!

    private var word = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 12
        containerView.layer.borderColor = UIColor.borderMuted.cgColor
        containerView.layer.borderWidth = 0
        containerView.backgroundColor = .backgroundOverlay
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        containerView.layer.borderColor = UIColor.borderMuted.cgColor
    }
}

// MARK: - Open methods
extension ConfirmWordConfirmationCell {
    func setWord(_ word: String, number: Int) {
        self.word = word
        numberLabel.setAttributedTextWith(text: "\(number)", font: .currentFont(withSize: 32, weight: .bold), textColor: .foregroundMuted)
        setWordLabel(with: "?????")
    }
    
    func setGuessed() {
        setWordLabel(with: word)
    }
}

// MARK: - Private methods
private extension ConfirmWordConfirmationCell {
    func setWordLabel(with word: String) {
        wordLabel.setAttributedTextWith(text: word, font: .currentFont(withSize: 32, weight: .bold), textColor: .foregroundDefault)
    }
}

