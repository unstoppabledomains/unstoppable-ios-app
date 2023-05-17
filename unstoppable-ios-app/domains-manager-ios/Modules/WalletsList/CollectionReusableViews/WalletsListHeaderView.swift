//
//  WalletsListHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2022.
//

import UIKit

final class WalletsListHeaderView: CollectionTextHeaderReusableView {
    
    static let topOffset: CGFloat = 15
    override class var reuseIdentifier: String { "WalletsListHeaderView" }
    override var isHorizontallyCentered: Bool { false }
    
    
    func setHeader(for section: WalletsListViewController.Section) {
        contentViewCenterYConstraint.constant = WalletsListHeaderView.topOffset / 2
        switch section {
        case .managed(let numberOfItems), .connected(let numberOfItems):
            contentView.isHidden = false
            let header = section.headerTitle + " ･ " + "\(numberOfItems)"
            setHeader(header)
        case .manageICLoud, .manageICloudExtraHeight, .empty:
            contentView.isHidden = true
            return
        }
    }
    
}


