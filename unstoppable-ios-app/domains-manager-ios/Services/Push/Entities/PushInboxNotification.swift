//
//  PushInboxNotification.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation


struct PushInboxNotification: Codable {
    let payloadId: Int
    let sender: String
    let epoch: String
    let payload: Payload
    let source: String
    let etime: String?
    
    enum CodingKeys: String, CodingKey {
        case payloadId = "payload_id"
        case sender
        case epoch
        case payload
        case source
        case etime
    }
}

// MARK: - Open methods
extension PushInboxNotification {
    struct Payload: Codable {
        let data: Data
//        let recipients: String
        let notification: Notification
        let verificationProof: String
        
        enum CodingKeys: String, CodingKey {
            case data
//            case recipients
            case notification
            case verificationProof = "verificationProof"
        }
    }
    
    struct Data: Codable {
        let app: String
        let sid: String
        let url: URL
        let acta: String
        let aimg: String
        let amsg: String
        let asub: String
        let icon: String
//        let type: Int?
        let epoch: String
        let etime: String?
        let hidden: String
        let sectype: String?
        let additionalMeta: String?
        
        enum CodingKeys: String, CodingKey {
            case app
            case sid
            case url
            case acta
            case aimg
            case amsg
            case asub
            case icon
//            case type
            case epoch
            case etime
            case hidden
            case sectype
            case additionalMeta = "additionalMeta"
        }
    }
    
    struct Notification: Codable {
        let body: String
        let title: String
    }

}

