//
//  MessagingChatMessageImageDataTypeDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2023.
//

import UIKit

struct MessagingChatMessageImageDataTypeDisplayInfo: Hashable {
    
    let encryptedData: Data
    let data: Data
    let image: UIImage
    
}

// MARK: - Open methods
extension MessagingChatMessageImageDataTypeDisplayInfo {
    init?(encryptedData: Data, data: Data) {
        guard let image = UIImage(data: data) else { return nil }
        self.encryptedData = encryptedData
        self.data = data
        self.image = image
    }
}
