//
//  ChatListDataTypeSelectionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.06.2023.
//

import UIKit

final class ChatListDataTypeSelectionCell: UICollectionViewCell {

    @IBOutlet private weak var segmentedControl: UDSegmentedControl!
    
    private var dataTypeChangedCallback: ((ChatsListDataType)->())?
    private var dataTypes: [ChatsListDataType] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

// MARK: - Open methods
extension ChatListDataTypeSelectionCell {
    func setWith(configuration: ChatsListViewController.DataTypeSelectionUIConfiguration) {
        dataTypeChangedCallback = configuration.dataTypeChangedCallback
        
        dataTypes.removeAll()
        segmentedControl.removeAllSegments()
        
        for (i, dataTypeConfiguration) in configuration.dataTypesConfigurations.enumerated() {
            let dataType = dataTypeConfiguration.dataType
            dataTypes.append(dataType)
            segmentedControl.insertSegment(withTitle: dataType.title,
                                           at: i,
                                           animated: false)
            segmentedControl.setBadgeValue(dataTypeConfiguration.badge,
                                           forSegment: i)
        }
        
        segmentedControl.selectedSegmentIndex = dataTypes.firstIndex(of: configuration.selectedDataType) ?? 0
    }
}

// MARK: - Actions
private extension ChatListDataTypeSelectionCell {
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        let selectedDataType = dataTypes[segmentedControl.selectedSegmentIndex]
        dataTypeChangedCallback?(selectedDataType)
    }
}
