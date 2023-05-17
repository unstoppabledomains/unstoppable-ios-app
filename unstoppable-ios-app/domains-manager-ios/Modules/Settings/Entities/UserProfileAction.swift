//
//  UserProfileAction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.03.2023.
//

import UIKit

enum UserProfileAction: String, CaseIterable, PullUpCollectionViewCellItem {
    case logOut
    
    var title: String {
        switch self {
        case .logOut:
            return String.Constants.logOut.localized()
        }
    }
    
    var titleColor: UIColor {
        switch self {
        case .logOut:
            return .foregroundDanger
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .logOut:
            return .foregroundDanger
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .logOut:
            return .clear
        }
    }
    
    var icon: UIImage {
        switch self {
        case .logOut:
            return .logOutIcon24
        }
    }
    
    var analyticsName: String { rawValue }
}
