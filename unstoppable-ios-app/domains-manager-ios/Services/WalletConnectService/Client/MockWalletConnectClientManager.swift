//
//  MockWalletConnectClientManager.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import Foundation
import WalletConnectSwift

final class MockWalletConnectClientManager {
    var sessions: [Session] = []
    var delegate: WalletConnectDelegate?
    private lazy var client: Client = {
        let clientMeta = Session.ClientMeta(name: String.Constants.mobileAppName.localized(),
                                            description: String.Constants.mobileAppDescription.localized(),
                                            icons: [String.Links.udLogoPng.urlString].compactMap { URL(string: $0) },
                                            url: String.Links.mainLanding.url!)
        let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString, peerMeta: clientMeta)
        return Client(delegate: self, dAppInfo: dAppInfo)
    }()
}

// MARK: - WalletConnectClientManagerProtocol
extension MockWalletConnectClientManager: WalletConnectClientServiceProtocol {
    func setUIHandler(_ uiHandler: WalletConnectClientUIHandler) {
        
    }
    
    func getClient() -> Client {
        self.client
    }
    
    func findSessions(by walletAddress: HexAddress) -> [WalletConnectSwift.Session] {
        sessions.filter({ $0.walletInfo?.accounts.map({$0.normalized})
            .contains(walletAddress.normalized) ?? false })
    }
    
    func connect() throws -> WCURL {
        let wcUrl =  WCURL(topic: UUID().uuidString.lowercased(),
                           bridgeURL: URL(fileURLWithPath: ""),
                           key: "")
        return wcUrl
    }
    
    func disconnect(walletAddress: HexAddress) throws {
        sessions.removeAll(where: { $0.walletInfo?.accounts.map({$0.normalized})
            .contains(walletAddress.normalized) ?? false })
    }
}

// MARK: - Mock functions
extension MockWalletConnectClientManager {
    func addSession(for address: HexAddress, name: String?) {
        let peerId = UUID().uuidString
        let peerMeta = Session.ClientMeta(name: name ?? "Rainbow",
                                          description: nil,
                                          icons: [],
                                          url: URL(fileURLWithPath: ""))
        let session = Session(url: (try! connect()),
                              dAppInfo: .init(peerId: peerId,
                                              peerMeta: peerMeta),
                              walletInfo: .init(approved: false,
                                                accounts: [address],
                                                chainId: 1,
                                                peerId: peerId,
                                                peerMeta: peerMeta))
        
        self.sessions.append(session)
    }
}

extension MockWalletConnectClientManager: WalletConnectSwift.ClientDelegate {
    func client(_ client: Client, didFailToConnect url: WCURL) { }
    func client(_ client: Client, didConnect url: WCURL) { }
    func client(_ client: Client, didConnect session: Session) { }
    func client(_ client: Client, didDisconnect session: Session) { }
    func client(_ client: Client, didUpdate session: Session) { }
}
