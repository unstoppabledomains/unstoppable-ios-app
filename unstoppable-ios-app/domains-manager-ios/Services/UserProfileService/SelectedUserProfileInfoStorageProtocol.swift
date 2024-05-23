//
//  SelectedUserProfileInfoStorageProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.03.2024.
//

import Foundation

protocol SelectedUserProfileInfoStorageProtocol {
    var selectedProfileId: String? { get set }
}

extension UserDefaults: SelectedUserProfileInfoStorageProtocol {
    var selectedProfileId: String? {
        get {
            UserDefaults.selectedProfileId
        }
        set {
            UserDefaults.selectedProfileId = newValue
        }
    }
}
