//
//  WCRequestsHandlingServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 23.02.2023.
//

import Foundation
import Combine
import XCTest
@testable import domains_manager_ios

// V1
import WalletConnectSwift

// V2
import WalletConnectSign

final class WCRequestsHandlingServiceTests: BaseTestClass {
    
    private var mockWCServiceV1: MockWCServiceV1!
    private var mockWCServiceV2: MockWCServiceV2!
    private var mockUIErrorHandler: MockWalletConnectUIErrorHandler!
    private var mockListener: MockWCServiceListener!
    private var wcRequestsHandlingService: WCRequestsHandlingService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        Constants.wcConnectionTimeout = 0.2
        mockWCServiceV1 = MockWCServiceV1()
        mockWCServiceV2 = MockWCServiceV2()
        mockUIErrorHandler = MockWalletConnectUIErrorHandler()
        wcRequestsHandlingService = WCRequestsHandlingService(walletConnectServiceV1: mockWCServiceV1,
                                                              walletConnectServiceV2: mockWCServiceV2)
        wcRequestsHandlingService.setUIHandler(mockUIErrorHandler)
        mockListener = MockWCServiceListener()
        wcRequestsHandlingService.addListener(mockListener)
    }
}

// MARK: - WC V1 Tests
extension WCRequestsHandlingServiceTests {
    // MARK: - V1 Connection tests
    private func makeWC1RequestWith(result: WCConnectionResult) async throws {
        verifyInitialState()
        try await wcRequestsHandlingService.handleWCRequest(getWCV1ConnectionRequest(), target: getConnectionTarget())
        try await waitFor(interval: 0.1)
        
        // Check request passed to service
        XCTAssertNotNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        
        mockWCServiceV1.callCompletion(result: result)
        try await waitFor(interval: 0.1)
    }
    
    func testWCV1ConnectionRequestHandled() async throws {
        try await makeWC1RequestWith(result: .success(nil))
        
        // Check listeners notified correctly
        XCTAssertTrue(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequestWith)
    }
    
    func testWCV1ConnectionRequestFailed() async throws {
        try await makeWC1RequestWith(result: .failure(WalletConnectRequestError.failedConnectionRequest))
        
        // Check listeners notified correctly
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertTrue(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequestWith)
        XCTAssertTrue(mockUIErrorHandler.didFailToConnect)
    }
    
    func testWCV1ConnectionRequestUserCancelled() async throws {
        try await makeWC1RequestWith(result: .failure(WalletConnectUIError.cancelled))
        
        // Check listeners notified correctly
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertTrue(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequestWith)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    // MARK: - V1 Sign tests
    func testWC1SignRequestHandled() async throws {
        verifyInitialState()
        
        callWC1Handler(requestType: .personalSign)
        try await waitFor(interval: 0.1)
        
        XCTAssertEqual(1, mockWCServiceV1.responseSentCount)
        XCTAssertEqual(0, mockWCServiceV2.responseSentCount)
        XCTAssertTrue(mockListener.didHandleExternalWCRequestWith)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
}

// MARK: - WC V2 Tests
extension WCRequestsHandlingServiceTests {
    // MARK: - V2 Connection tests
    private func makeWC2RequestWith(result: WCConnectionResult) async throws {
        verifyInitialState()
        try await wcRequestsHandlingService.handleWCRequest(getWCV2ConnectionRequest(), target: getConnectionTarget())
        try await waitFor(interval: 0.1)
        
        // Check request is not passed to any service, waiting for WC2 publisher
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertNil(mockWCServiceV1.completion)
        
        mockWCServiceV2.pSessionProposalPublisher.send(getWC2SessionProposal())
        try await waitFor(interval: 0.1)
        XCTAssertNotNil(mockWCServiceV2.completion)
        XCTAssertNil(mockWCServiceV1.completion)
        
        mockWCServiceV2.callCompletion(result: result)
        try await waitFor(interval: 0.1)
    }
    
    func testWCV2ConnectionRequestHandled() async throws {
        try await makeWC2RequestWith(result: .success(nil))
        
        // Check listeners notified correctly
        XCTAssertTrue(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequestWith)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    func testWCV2ConnectionRequestFailed() async throws {
        try await makeWC2RequestWith(result: .failure(WalletConnectRequestError.failedConnectionRequest))
        
        // Check listeners notified correctly
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertTrue(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequestWith)
        XCTAssertTrue(mockUIErrorHandler.didFailToConnect)
    }
    
    func testWCV2ConnectionRequestUserCancelled() async throws {
        try await makeWC2RequestWith(result: .failure(WalletConnectUIError.cancelled))
        
        // Check listeners notified correctly
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertTrue(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequestWith)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    // MARK: - V2 Sign tests
    func testWC2SignRequestHandled() async throws {
        verifyInitialState()
        
        callWC2Handler(requestType: .personalSign)
        try await waitFor(interval: 0.1)
        
        XCTAssertEqual(0, mockWCServiceV1.responseSentCount)
        XCTAssertEqual(1, mockWCServiceV2.responseSentCount)
        XCTAssertTrue(mockListener.didHandleExternalWCRequestWith)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
}
// MARK: - Private methods
private extension WCRequestsHandlingServiceTests {
    func verifyInitialState() {
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertEqual(0, mockWCServiceV1.responseSentCount)
        XCTAssertEqual(0, mockWCServiceV2.responseSentCount)
        XCTAssertFalse(mockWCServiceV1.didCallConnectionTimeout)
        XCTAssertFalse(mockWCServiceV2.didCallConnectionTimeout)
        
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequestWith)
        
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    func getWCV1URL() -> WalletConnectSwift.WCURL {
        .init(topic: "topic", bridgeURL: URL(string: "https://g.com")!, key: "key")
    }
    
    func getWCV1ConnectionRequest() -> WCRequest {
        WCRequest.connectWallet(.version1(getWCV1URL()))
    }
    
    func getConnectionTarget() -> (UDWallet, DomainItem) {
        (createLocallyGeneratedBackedUpUDWallet(), createMockDomainItem())
    }
    
    func getWCV2URI() -> WalletConnectSign.WalletConnectURI {
        .init(topic: "topic", symKey: "symKey", relay: .init(protocol: "", data: nil))
    }
    
    func getWCV2ConnectionRequest() -> WCRequest {
        WCRequest.connectWallet(.version2(getWCV2URI()))
    }
    
    func getWC2SessionProposal() -> WalletConnectSign.Session.Proposal {
        // Workaround due to no public initializer for Proposal struct in WC SDK
        struct ProposalClone: Codable {
            var id: String
            let pairingTopic: String
            let proposer: WalletConnectSign.AppMetadata
            let requiredNamespaces: [String: WalletConnectSign.ProposalNamespace]
            let proposal: SessionProposalClone
        }
        struct SessionProposalClone: Codable {
            let relays: [RelayProtocolOptions]
            let proposer: ParticipantClone
            let requiredNamespaces: [String: ProposalNamespace]
        }
        struct ParticipantClone: Codable {
            let publicKey: String
            let metadata: WalletConnectSign.AppMetadata
        }
        
        let appMetaData = WalletConnectSign.AppMetadata(name: "name", description: "des", url: "https://g.com", icons: [])
        let participantClone = ParticipantClone(publicKey: "key", metadata: appMetaData)
        let sessionProposalClone = SessionProposalClone(relays: [],
                                                        proposer: participantClone,
                                                        requiredNamespaces: [:])
        let proposalClone = ProposalClone(id: "id",
                                          pairingTopic: "topic",
                                          proposer: appMetaData,
                                          requiredNamespaces: [:],
                                          proposal: sessionProposalClone)
        let data = proposalClone.jsonData()!
        
        let proposal: WalletConnectSign.Session.Proposal = WalletConnectSign.Session.Proposal.genericObjectFromData(data)!
        return proposal
    }
    
    func callWC1Handler(requestType: WalletConnectRequestType) {
        let handlers = mockWCServiceV1.requestHandlers as! [WalletConnectV1SignTransactionHandler]
        let handler = handlers.first(where: { $0.requestType == requestType })!
        
        let request = WalletConnectSwift.Request(url: getWCV1URL(), method: requestType.rawValue)
        handler.handle(request: request)
    }
    
    func callWC2Handler(requestType: WalletConnectRequestType) {
        mockWCServiceV2.pSessionRequestPublisher.send(.init(topic: "topic", method: requestType.rawValue, params: AnyCodable(""), chainId: .init("eip155:1")!))
    }
}

private final class MockWCServiceV1: WalletConnectV1RequestHandlingServiceProtocol {
    
    // Mock properties
    var errorToFail: Error?
    private(set) var didCallConnectionTimeout = false
    private(set) var completion: WCConnectionResultCompletion?
    private(set) var responseSentCount = 0
    private(set) var requestHandlers = [RequestHandler]()
    
    func callCompletion(result: WCConnectionResult) {
        completion?(result)
        completion = nil
    }
    
    // WalletConnectV1RequestHandlingServiceProtocol properties
    var appDisconnectedCallback: domains_manager_ios.WCAppDisconnectedCallback?
    var willHandleRequestCallback: domains_manager_ios.EmptyCallback?
    
    func registerRequestHandler(_ requestHandler: RequestHandler) {
        requestHandlers.append(requestHandler)
    }
    
    func connectAsync(to requestURL: WalletConnectSwift.WCURL,
                      completion: @escaping domains_manager_ios.WCConnectionResultCompletion) {
        self.completion = completion
    }
    
    func sendResponse(_ response: WalletConnectSwift.Response) {
        responseSentCount += 1
    }
    
    func connectionTimeout() {
        didCallConnectionTimeout = true
    }
    
    func handlePersonalSign(request: WalletConnectSwift.Request) async throws -> WalletConnectSwift.Response {
        try await getResponse(for: request)
    }
    
    func handleSignTx(request: WalletConnectSwift.Request) async throws -> WalletConnectSwift.Response {
        try await getResponse(for: request)
    }
    
    func handleGetTransactionCount(request: WalletConnectSwift.Request) async throws -> WalletConnectSwift.Response {
        try await getResponse(for: request)
    }
    
    func handleEthSign(request: WalletConnectSwift.Request) async throws -> WalletConnectSwift.Response {
        try await getResponse(for: request)
    }
    
    func handleSendTx(request: WalletConnectSwift.Request) async throws -> WalletConnectSwift.Response {
        try await getResponse(for: request)
    }
    
    func handleSendRawTx(request: WalletConnectSwift.Request) async throws -> WalletConnectSwift.Response {
        try await getResponse(for: request)
    }
    
    func handleSignTypedData(request: WalletConnectSwift.Request) async throws -> WalletConnectSwift.Response {
        try await getResponse(for: request)
    }
    
    private func getResponse(for request: WalletConnectSwift.Request) async throws -> WalletConnectSwift.Response {
        if let errorToFail {
            throw errorToFail
        }
        return WalletConnectSwift.Response.signature("", for: request)
    }
}

private final class MockWCServiceV2: WalletConnectV2RequestHandlingServiceProtocol, WalletConnectV2PublishersProvider {
    
    private(set) var pSessionProposalPublisher = PassthroughSubject<WalletConnectSign.Session.Proposal, Never>()
    var sessionProposalPublisher: AnyPublisher<WalletConnectSign.Session.Proposal, Never> { pSessionProposalPublisher.eraseToAnyPublisher() }
    
    private(set) var pSessionRequestPublisher = PassthroughSubject<WalletConnectSign.Request, Never>()
    var sessionRequestPublisher: AnyPublisher<WalletConnectSign.Request, Never> { pSessionRequestPublisher.eraseToAnyPublisher() }
    
    // Mock properties
    var errorToFail: Error?
    private(set) var didCallConnectionTimeout = false
    private(set) var completion: WCConnectionResultCompletion?
    private(set) var responseSentCount = 0
    
    func callCompletion(result: WCConnectionResult) {
        completion?(result)
        completion = nil
    }
    
    // WalletConnectV2RequestHandlingServiceProtocol properties
    var appDisconnectedCallback: domains_manager_ios.WCAppDisconnectedCallback?
    var willHandleRequestCallback: domains_manager_ios.EmptyCallback?
    var publishersProvider: WalletConnectV2PublishersProvider { self }
    
    func pairClient(uri: WalletConnectUtils.WalletConnectURI) async throws {
        
    }
    
    func handleConnectionProposal(_ proposal: domains_manager_ios.WC2ConnectionProposal,
                                  completion: @escaping domains_manager_ios.WCConnectionResultCompletion) {
        self.completion = completion
    }
    
    func sendResponse(_ response: JSONRPC.RPCResult, toRequest request: WalletConnectSign.Request) async throws {
        responseSentCount += 1
    }
    
    func connectionTimeout() {
        didCallConnectionTimeout = true
    }
    
    func handlePersonalSign(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        try await getResponse()
    }
    
    func handleEthSign(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        try await getResponse()
    }
    
    func handleSignTx(request: WalletConnectSign.Request) async throws -> [JSONRPC.RPCResult] {
        let response = try await getResponse()
        return [response]
    }
    
    func handleSendTx(request: WalletConnectSign.Request) async throws -> [JSONRPC.RPCResult] {
        let response = try await getResponse()
        return [response]
    }
    
    func handleGetTransactionCount(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        try await getResponse()
    }
    
    func handleSendRawTx(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        try await getResponse()
    }
    
    func handleSignTypedData(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        try await getResponse()
    }
    
    func getResponse() async throws -> JSONRPC.RPCResult {
        if let errorToFail {
            throw errorToFail
        }
        return .response(AnyCodable(""))
    }
}

// MARK: - WalletConnectUIErrorHandler
private final class MockWalletConnectUIErrorHandler: WalletConnectUIErrorHandler {
    
    private(set) var didFailToConnect = false
    
    func didFailToConnect(with error: domains_manager_ios.WalletConnectRequestError) async {
        didFailToConnect = true
    }
}

// MARK: - WalletConnectServiceConnectionListener
private final class MockWCServiceListener: WalletConnectServiceConnectionListener {
    
    private(set) var didConnectCalled = false
    private(set) var didDisconnectCalled = false
    private(set) var didCompletionAttemptCalled = false
    private(set) var didHandleExternalWCRequestWith = false
    
    func didConnect(to app: domains_manager_ios.PushSubscriberInfo?) {
        didConnectCalled = true
    }
    
    func didDisconnect(from app: domains_manager_ios.PushSubscriberInfo?) {
        didDisconnectCalled = true
    }
    
    func didCompleteConnectionAttempt() {
        didCompletionAttemptCalled = true
    }
    
    func didHandleExternalWCRequestWith(result: WCExternalRequestResult) {
        didHandleExternalWCRequestWith = true
    }
}
