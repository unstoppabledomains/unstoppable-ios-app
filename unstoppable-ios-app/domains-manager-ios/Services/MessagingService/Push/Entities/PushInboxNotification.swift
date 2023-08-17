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
    let source: String?
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
        let recipients: [String]
        let notification: Notification?
        let verificationProof: String?
        
        enum CodingKeys: String, CodingKey {
            case data
            case recipients
            case notification
            case verificationProof = "verificationProof"
        }
        
        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<PushInboxNotification.Payload.CodingKeys> = try decoder.container(keyedBy: PushInboxNotification.Payload.CodingKeys.self)
            self.data = try container.decode(PushInboxNotification.Data.self, forKey: PushInboxNotification.Payload.CodingKeys.data)
            if let dict = try? container.decode([String: String?].self, forKey: PushInboxNotification.Payload.CodingKeys.recipients) {
                self.recipients = Array(dict.keys)
            } else {
                self.recipients = []
            }
            self.notification = try? container.decodeIfPresent(PushInboxNotification.Notification.self, forKey: PushInboxNotification.Payload.CodingKeys.notification)
            self.verificationProof = try container.decodeIfPresent(String.self, forKey: PushInboxNotification.Payload.CodingKeys.verificationProof)
        }
    }
    
    struct Data: Codable {
        let app: String?
        let sid: String?
        let url: String?
        let acta: String?
        let aimg: String?
        let amsg: String
        let asub: String
        let icon: String?
//        let type: Int?
        let etime: String?
        let hidden: String?
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

