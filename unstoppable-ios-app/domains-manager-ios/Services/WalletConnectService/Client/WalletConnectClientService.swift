//
//  WalletConnectClientManager.swift
//  domains-manager-ios
//
//  Created by Roman on 14.07.2022.
//

import Foundation
import Web3
import WalletConnectSwift

protocol WalletConnectClientServiceProtocol: AnyObject {
    func setUIHandler(_ uiHandler: WalletConnectClientUIHandler)
    func getClient() -> Client
    func findSessions(by walletAddress: HexAddress) -> [Session]
    func connect() throws -> WCURL
    func disconnect(walletAddress: HexAddress) throws
    var delegate: WalletConnectDelegate? { get set }
}

protocol WalletConnectDelegate: AnyObject {
    func failedToConnect()
    func didConnect(to walletAddress: HexAddress?, with wcRegistryWallet: WCRegistryWalletProxy?)
    func didDisconnect(from accounts: [HexAddress]?, with wcRegistryWallet: WCRegistryWalletProxy?)
}


protocol WalletConnectClientUIHandler: AnyObject {
    func didDisconnect(walletDisplayInfo: WalletDisplayInfo)
}


struct WCRegistryWalletProxy {
    let host: String
    
    init?(_ walletInfo: Session.WalletInfo?) {
        guard let info = walletInfo else { return nil }
        guard let host = info.peerMeta.url.host else { return nil }
        self.host = host
    }
}

class WCClientConnections: DefaultsStorage<WalletConnectClientService.ConnectionData> {
    override init() {
        super.init()
        storageKey = "CLIENT_CONNECTIONS_STORAGE"
        q = DispatchQueue(label: "work-queue-client-connections")
    }
    
    func save(newConnection: WalletConnectClientService.ConnectionData) {
        super.save(newElement: newConnection)
    }
}

final class WalletConnectClientService {
    struct ConnectionData: Codable, Equatable {
//        let targetWalletAddress: HexAddress?
        let session: Session
    }

    enum Error: Swift.Error {
        case reconnectionToExistingClient
        case failedGenerateRandom
        case failedGenerateUrl
    }
        
    weak var delegate: WalletConnectDelegate?
    private weak var uiHandler: WalletConnectClientUIHandler?
    let clientConnections = WCClientConnections()
    private let udWalletsService: UDWalletsServiceProtocol
    
    init(udWalletsService: UDWalletsServiceProtocol) {
        self.udWalletsService = udWalletsService
        try? self.reconnectExistingSessions()
    }
    
    private var _client: Client!
    public func getClient() -> Client {
        guard _client == nil else { return _client! }
        let clientMeta = Session.ClientMeta(name: String.Constants.mobileAppName.localized(),
                                            description: String.Constants.mobileAppDescription.localized(),
                                            icons: [String.Links.udLogoPng.urlString].compactMap { URL(string: $0) },
                                            url: String.Links.mainLanding.url!)
        let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString, peerMeta: clientMeta)
        _client = Client(delegate: self, dAppInfo: dAppInfo)
        return _client
    }
    
    
    static let bridgeHostBaseUrl = "bridge.walletconnect.org"
    static var bridgeHostUrl: String {
        let char = "abcdefghijklmnopqrstuvwxyz0123456789".randomElement()
        return String(char!) + String.dotSeparator + bridgeHostBaseUrl
    }

    private func reconnectExistingSessions() throws {
        let oldConnections = clientConnections.retrieveAll()
        try oldConnections.forEach {
            try getClient().reconnect(to: $0.session)
        }
    }
    
}

extension WalletConnectClientService: WalletConnectClientServiceProtocol {
    func setUIHandler(_ uiHandler: WalletConnectClientUIHandler) {
        self.uiHandler = uiHandler
    }
    
    func connect() throws -> WCURL {
        guard let url = URL(string: "https://\(Self.bridgeHostUrl)") else {
            throw Error.failedGenerateUrl
        }
        let wcUrl =  WCURL(topic: UUID().uuidString.lowercased(),
                           bridgeURL: url,
                           key: try randomKey())
        try getClient().connect(to: wcUrl)
        return wcUrl
    }
    
    func disconnect(walletAddress: HexAddress) throws {
        let sessions = findSessions(by: walletAddress)
        try sessions.forEach({ try getClient().disconnect(from: $0) })
    }
    
    public func findSessions(by walletAddress: HexAddress) -> [Session] {
        clientConnections.retrieveAll().filter({ $0.session.walletInfo?.accounts.map({$0.normalized}).contains(walletAddress.normalized) ?? false })
        .map({$0.session})
    }
}

extension WalletConnectClientService: WalletConnectSwift.ClientDelegate {
    func client(_ client: Client, didFailToConnect url: WCURL) {
        delegate?.failedToConnect()
    }
    
    func client(_ client: Client, didConnect url: WCURL) {
        // do nothing
        Debugger.printInfo("WC: CLIENT DID CONNECT - WCURL: \(url)")
    }
    
    func client(_ client: Client, didConnect session: Session) {
        Debugger.printInfo("WC: CLIENT DID CONNECT - SESSION: \(session)")
        guard let walletAddress = session.walletInfo?.accounts.first else {
            Debugger.printFailure("Wallet has insufficient info: \(String(describing: session.walletInfo))", critical: true)
            delegate?.didConnect(to: nil, with: nil)
            return
        }

        if clientConnections.retrieveAll().filter({$0.session == session}).first == nil {
            clientConnections.save(newConnection: ConnectionData(session: session))
        } else {
            Debugger.printWarning("Existing session got reconnected")
        }
        
        delegate?.didConnect(to: walletAddress, with: WCRegistryWalletProxy(session.walletInfo))
    }
    
    func client(_ client: Client, didDisconnect session: Session) {
        Task  {
            guard let connectionToRemove = self.clientConnections.retrieveAll()
                                                .first(where: {$0.session == session}) else {
                Debugger.printFailure("Session disconnected that was not in cache", critical: true)
                return
            }
            
            // accounts in the incoming `session` may be wrong, take them from the cache
            let accounts = connectionToRemove.session.walletInfo?.accounts
            
            if let walletAddress = accounts?.first,
               let toRemove = udWalletsService.find(by: walletAddress) {
                if let walletDisplayInfo = WalletDisplayInfo(wallet: toRemove, domainsCount: 0) {
                    self.uiHandler?.didDisconnect(walletDisplayInfo: walletDisplayInfo)
                }
                udWalletsService.remove(wallet: toRemove)
                Debugger.printWarning("Disconnected external wallet: \(toRemove.aliasName)")
            }
            
            guard let _ = await self.clientConnections.remove(when: {$0.session == session}) else {
                Debugger.printFailure("Session disconnected that was not in cache", critical: true)
                return
            }
            
            self.delegate?.didDisconnect(from: accounts, with: WCRegistryWalletProxy(session.walletInfo))
        }
    }
    
    func client(_ client: Client, didUpdate session: Session) {
        // do nothing
    }
    
    // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
    private func randomKey() throws -> String {
        var bytes = [Int8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return Data(bytes: bytes, count: 32).toHexString()
        } else {
            throw Error.failedGenerateRandom
        }
    }
}

extension WCURL {
    public var absoluteStringCorrect: String {
        let bridge = "https%253A%252F%252F\(self.bridgeURL.host!)"
        return ("wc:\(self.topic)@\(self.version)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "") + "%3Fbridge%3D\(bridge)" + "%26key%3D\(key)"
    }
}

extension Session: Equatable {
    public static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.url.topic == rhs.url.topic
    }
    
    public func getWalletName() -> String? {
        self.walletInfo?.peerMeta.name
    }
}
