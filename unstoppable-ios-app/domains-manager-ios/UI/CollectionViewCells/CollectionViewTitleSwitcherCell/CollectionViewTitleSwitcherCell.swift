//
//  CollectionViewTitleSwitcherCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.10.2022.
//

import UIKit

typealias CollectionViewSwitcherCellCallback = (Bool)->()

final class CollectionViewTitleSwitcherCell: BaseListCollectionViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var switcher: UISwitch!
    
    private var valueChangedCallback: CollectionViewSwitcherCellCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.isSelectable = false
    }

  
}

// MARK: - Open methods
extension CollectionViewTitleSwitcherCell {
    func setWith(title: String, isOn: Bool, valueChangedCallback: @escaping CollectionViewSwitcherCellCallback) {
        self.valueChangedCallback = valueChangedCallback
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .foregroundDefault)
        switcher.isOn = isOn
    }
}

// MARK: - Actions
private extension CollectionViewTitleSwitcherCell {
    @IBAction func switchValueChanged(_ sender: Any) {
        valueChangedCallback?(switcher.isOn)
    }
}
