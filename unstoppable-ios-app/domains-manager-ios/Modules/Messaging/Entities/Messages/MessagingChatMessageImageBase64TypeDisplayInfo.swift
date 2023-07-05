//
//  MessagingChatMessageImageTypeDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.06.2023.
//

import Foundation

struct MessagingChatMessageImageBase64TypeDisplayInfo: Hashable {
  
    let base64: String
    let encryptedContent: String
    let base64Image: String // Make constant due to performance issues
    
    init(base64: String, encryptedContent: String) {
        self.base64 = base64
        self.encryptedContent = encryptedContent
        self.base64Image = Base64DataTransformer.removeDataFrom(string: base64)
    }
    
}
