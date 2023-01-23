//
//  ConfirmWordListCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.04.2022.
//

import UIKit

final class ConfirmWordListCell: UICollectionViewCell {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var wordLabel: UILabel!
    @IBOutlet private weak var stateImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 12
        setUIForState(.default)
    }
    
}

// MARK: - Open methods
extension ConfirmWordListCell {
    func setWord(_ word: String) {
        wordLabel.setAttributedTextWith(text: word,
                                        font: .currentFont(withSize: 16, weight: .semibold),
                                        textColor: .foregroundDefault)
    }
    
    func blinkState(_ state: State) {
        setUIForState(state)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.setUIForState(.default)
        }
    }
}

// MARK: - Private methods
private extension ConfirmWordListCell {
    func setUIForState(_ state: State) {
        switch state {
        case .default:
            containerView.backgroundColor = .backgroundMuted2
            wordLabel.isHidden = false
            stateImageView.isHidden = true
        case .error:
            containerView.backgroundColor = .backgroundDangerEmphasis
            wordLabel.isHidden = true
            stateImageView.isHidden = false
            stateImageView.image = .crossWhite
        case .success:
            containerView.backgroundColor = .backgroundSuccessEmphasis
            wordLabel.isHidden = true
            stateImageView.isHidden = false
            stateImageView.image = .checkCircleWhite
        }
    }
}

extension ConfirmWordListCell {
    enum State {
        case `default`, error, success
    }
}
