//
//  DomainsCollectionDataTypeSelectionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.03.2023.
//

import UIKit

final class DomainsCollectionDataTypeSelectionCell: UICollectionViewCell {

    @IBOutlet private weak var segmentPicker: SegmentPicker!
    
    private var dataTypeChangedCallback: DomainsCollectionVisibleDataTypeCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
}

// MARK: - Open methods
extension DomainsCollectionDataTypeSelectionCell {
    func setupWith(selectedDataType: DomainsCollectionVisibleDataType, dataTypeChangedCallback: @escaping DomainsCollectionVisibleDataTypeCallback) {
        self.dataTypeChangedCallback = dataTypeChangedCallback
        segmentPicker.selectedSegmentIndex = selectedDataType.rawValue
    }
}

// MARK: - Actions
private extension DomainsCollectionDataTypeSelectionCell {
    @IBAction func segmentPickerValueChanged(_ sender: Any) {
        guard let dataType = DomainsCollectionVisibleDataType(rawValue: segmentPicker.selectedSegmentIndex) else { return }
        
        dataTypeChangedCallback?(dataType)
    }
}

// MARK: - Setup methods
private extension DomainsCollectionDataTypeSelectionCell {
    func setup() {
        UIView.performWithoutAnimation {
            segmentPicker.layoutType = .fillParent
            for (i, dataType) in DomainsCollectionVisibleDataType.allCases.enumerated() {
                segmentPicker.insertSegment(with: dataType.icon, title: dataType.title, at: i, animated: false)
            }
        }
    }
}
