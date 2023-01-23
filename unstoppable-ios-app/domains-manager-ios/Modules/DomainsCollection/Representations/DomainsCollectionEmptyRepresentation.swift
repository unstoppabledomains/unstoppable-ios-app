//
//  DomainsCollectionEmptyRepresentation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

final class DomainsCollectionEmptyRepresentation {
    var mintPressedCallback: EmptyCallback
    var buyPressedCallback: EmptyCallback
    
    init(mintPressedCallback: @escaping EmptyCallback,
         buyPressedCallback: @escaping EmptyCallback) {
        self.mintPressedCallback = mintPressedCallback
        self.buyPressedCallback = buyPressedCallback
    }
}

extension DomainsCollectionEmptyRepresentation: DomainsCollectionRepresentation {
    var isScrollEnabled: Bool { false }

    func layout() -> UICollectionViewLayout { .fullSizeLayout() }
    
    func snapshot() -> DomainsCollectionSnapshot {
        var snapshot = DomainsCollectionSnapshot()
        snapshot.appendSections([.other])
        snapshot.appendItems([.empty(mintPressed: mintPressedCallback,
                                     buyPressed: buyPressedCallback)])
        
        return snapshot
    }
}
