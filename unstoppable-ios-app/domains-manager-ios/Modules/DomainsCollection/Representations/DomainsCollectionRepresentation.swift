//
//  DomainsCollectionRepresentation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

@MainActor
protocol DomainsCollectionRepresentation {
    var isScrollEnabled: Bool { get }
    func layout() -> UICollectionViewLayout
    func snapshot() -> DomainsCollectionSnapshot
}
