//
//  SelectionPopoverViewItem.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.07.2024.
//

import Foundation

protocol SelectionPopoverViewItem: Hashable {
    var selectionTitle: String { get }
}

extension BlockchainType: SelectionPopoverViewItem {
    var selectionTitle: String { shortCode }
}
