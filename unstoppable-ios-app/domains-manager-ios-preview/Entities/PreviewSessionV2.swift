//
//  PreviewSessionV2.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

struct SessionV2 {
    
    var peer: Peer = .init()
    
    var description: String { "" }
    
    
    struct Peer {
        var url: String = ""
        var name: String = ""
    }
    
    struct Proposal: Equatable, Codable {
        
    }
}
