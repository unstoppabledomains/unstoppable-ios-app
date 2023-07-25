//
//  XMTPEnvironmentNamespace.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import XMTP

enum XMTPEnvironmentNamespace {
    
    enum KnownType: String {
        case text
        case attachment
    }
    
    struct ChatServiceMetadata: Codable {
        let encodedContainer: ConversationContainer
    }

    struct MessageServiceMetadata: Codable {
        let encodedContentData: Data
        let type: TypeDescription
        let compression: Xmtp_MessageContents_Compression
        
        init(encodedContent: EncodedContent) {
            self.encodedContentData = encodedContent.content
            self.compression = encodedContent.compression
            self.type = TypeDescription(contentType: encodedContent.type)
        }
        
        var encodedContent: EncodedContent {
            var content = EncodedContent()
            content.content = encodedContentData
            content.type = type.contentType
            content.compression = compression
            return content
        }
        
        struct TypeDescription: Codable {
            var authorityID: String
            var typeID: String
            var versionMajor: UInt32
            var versionMinor: UInt32
            
            init(contentType: Xmtp_MessageContents_ContentTypeId) {
                self.authorityID = contentType.authorityID
                self.typeID = contentType.typeID
                self.versionMajor = contentType.versionMajor
                self.versionMinor = contentType.versionMinor
            }
            
            var contentType: Xmtp_MessageContents_ContentTypeId {
                var type = Xmtp_MessageContents_ContentTypeId()
                type.authorityID = authorityID
                type.typeID = typeID
                type.versionMajor = versionMajor
                type.versionMinor = versionMinor
                return type
            }
        }
    }
    
    struct XMTPSocketMessageServiceContent {
        let xmtpMessage: DecodedMessage
    }
    
}

extension Xmtp_MessageContents_Compression: Codable { }
