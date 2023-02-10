//
//  WalletConnectClientService_V2.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 10.02.2023.
//

import Foundation
// V2
//import WalletConnectUtils
import WalletConnectSign
//import WalletConnectEcho

protocol WalletConnectClientServiceV2Protocol: AnyObject {
//    func setUIHandler(_ uiHandler: WalletConnectClientUIHandler)
//    func getClient() -> Client
//    func findSessions(by walletAddress: HexAddress) -> [Session]
    func connect() async throws -> WalletConnectURI
//    func disconnect(walletAddress: HexAddress) throws
//    var delegate: WalletConnectDelegate? { get set }
}

final class WalletConnectClientServiceV2: WalletConnectClientServiceV2Protocol {
    
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

final class MockWalletConnectV2ClientManager: WalletConnectClientServiceV2Protocol {
    func connect() async throws -> WalletConnectUtils.WalletConnectURI {
        throw WalletConnectError.walletConnectNil
    }
}
