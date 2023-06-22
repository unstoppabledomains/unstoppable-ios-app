//
//  PushChannel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct PushChannel: Codable {
    let id: Int
    let channel: String
    let ipfshash: String
    let name: String
    let info: String
    let url: URL
    let icon: URL
    let processed: Int
    let attempts: Int
    let verified_status: Int
    let alias_address: String?
    let activation_status: Int
    let timestamp: String
    let counter: Int?
    let subgraph_details: String?
    let alias_blockchain_id: String?
    let alias_verification_event: String?
    let blocked: Int
    let is_alias_verified: Int
    let subgraph_attempts: Int
    let subscriber_count: Int
}
