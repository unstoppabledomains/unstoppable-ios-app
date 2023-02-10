//
//  WalletConnectClientService_V2.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 10.02.2023.
//

import Foundation
// V2
import WalletConnectUtils
import WalletConnectSign
import WalletConnectEcho

final class WalletConnectClientServiceV2 {
    
    let namespaces: [String: ProposalNamespace] = [
        "eip155": ProposalNamespace(
            chains: [
                Blockchain("eip155:1")!,
                Blockchain("eip155:137")!
            ],
            methods: [
                "eth_sendTransaction",
                "personal_sign",
                "eth_signTypedData"
            ], events: [], extensions: nil
        )]
    
    func connect() async throws -> WalletConnectURI {
        let uri = try await Pair.instance.create()
        try await Sign.instance.connect(requiredNamespaces: namespaces, topic: uri.topic)
        
        return uri
    }
}
