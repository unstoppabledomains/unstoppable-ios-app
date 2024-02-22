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

// V2
import WalletConnectSign

final class WCRequestsHandlingServiceTests: BaseTestClass {
    
    private var mockWCServiceV2: MockWCServiceV2!
    private var mockUIErrorHandler: MockWalletConnectUIErrorHandler!
    private var mockListener: MockWCServiceListener!
    private var wcRequestsHandlingService: WCRequestsHandlingService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        configureWC2()
        Constants.wcConnectionTimeout = 0.2
        mockWCServiceV2 = MockWCServiceV2()
        mockUIErrorHandler = MockWalletConnectUIErrorHandler()
        wcRequestsHandlingService = WCRequestsHandlingService(walletConnectServiceV2: mockWCServiceV2,
                                                              walletConnectExternalWalletHandler: MockWalletConnectExternalWalletHandler())
        wcRequestsHandlingService.setUIHandler(mockUIErrorHandler)
        mockListener = MockWCServiceListener()
        wcRequestsHandlingService.addListener(mockListener)
    }
    
    private func configureWC2() {
        Networking.configure(projectId: AppIdentificators.wc2ProjectId,
                             socketFactory: SocketFactory())
        
        let metadata = AppMetadata(name: String.Constants.mobileAppName.localized(),
                                   description: String.Constants.mobileAppDescription.localized(),
                                   url: String.Links.mainLanding.urlString,
                                   icons: [String.Links.udLogoPng.urlString], 
                                   redirect: .init(native: "", universal: nil))
        
        Pair.configure(metadata: metadata)
    }
}


// MARK: - WC V2 Tests
extension WCRequestsHandlingServiceTests {
    // MARK: - V2 Connection tests
    private func makeWC2RequestWith(result: WCConnectionResult) async throws {
        try await handleWCV2ConnectionRequestAndWait()
        
        // Check request is not passed to any service, waiting for WC2 publisher
        XCTAssertNil(mockWCServiceV2.completion)
        
        mockWCServiceV2.pSessionProposalPublisher.send((getWC2SessionProposal(), nil))
        try await waitFor(interval: 0.1)
        XCTAssertNotNil(mockWCServiceV2.completion)
        
        mockWCServiceV2.callCompletion(result: result)
        try await waitFor(interval: 0.1)
    }
    
    
    func testWCV2ConnectionRequestFailed() async throws {
        verifyInitialState()
        try await makeWC2RequestWith(result: .failure(WalletConnectRequestError.failedConnectionRequest))
        
        // Check listeners notified correctly
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertTrue(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequest)
        XCTAssertTrue(mockUIErrorHandler.didFailToConnect)
    }
    
    func testWCV2ConnectionRequestUserCancelled() async throws {
        verifyInitialState()
        try await makeWC2RequestWith(result: .failure(uiCancelledError))
        
        // Check listeners notified correctly
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertTrue(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    // MARK: - V2 Sign tests
    private func makeWC2SignRequest() async throws {
        callWC2Handler(requestType: .personalSign)
        try await waitFor(interval: 0.1)
    }
    
    func testWC2SignRequestHandled() async throws {
        verifyInitialState()
        try await makeWC2SignRequest()
        XCTAssertEqual(1, mockWCServiceV2.responseSentCount)
        XCTAssertTrue(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    func testWC2SignRequestFailed() async throws {
        verifyInitialState()
        mockWCServiceV2.errorToFail = WalletConnectRequestError.failedConnectionRequest
        try await makeWC2SignRequest()
        XCTAssertEqual(1, mockWCServiceV2.responseSentCount)
        XCTAssertTrue(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertTrue(mockUIErrorHandler.didFailToConnect)
    }
    
    func testWC2SignRequestCancelled() async throws {
        verifyInitialState()
        mockWCServiceV2.errorToFail = uiCancelledError
        try await makeWC2SignRequest()
        XCTAssertEqual(1, mockWCServiceV2.responseSentCount)
        XCTAssertTrue(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
}

// MARK: - Request timeout
extension WCRequestsHandlingServiceTests {
    func testWCV2RequestTimeout() async throws {
        verifyInitialState()
        
        try await handleWCV2ConnectionRequestAndProposalAndWait()
        try await awaitForLongerThanConnectionTimeout()
        
        XCTAssertTrue(mockWCServiceV2.didCallConnectionTimeout)
    }
    
    func testRequestTimeoutAfterExpecting() async throws {
        verifyInitialState()
        wcRequestsHandlingService.expectConnection()
        XCTAssertFalse(mockWCServiceV2.didCallConnectionTimeout)
        
        try await awaitForLongerThanConnectionTimeout()
        
        XCTAssertTrue(mockWCServiceV2.didCallConnectionTimeout)
    }
}

// MARK: - Private methods
private extension WCRequestsHandlingServiceTests {
    var uiCancelledError: Error { WalletConnectUIError.cancelled }
    
    func verifyInitialState() {
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertEqual(0, mockWCServiceV2.responseSentCount)
        XCTAssertFalse(mockWCServiceV2.didCallConnectionTimeout)
        
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequest)
        
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    func handleWCV2ConnectionRequestAndWait(topic: String = "topic") async throws {
        try await wcRequestsHandlingService.handleWCRequest(getWCV2ConnectionRequest(topic: topic), target: getConnectionTarget())
        try await waitFor(interval: 0.1)
    }
    
    func handleWCV2ConnectionRequestAndProposalAndWait(topic: String = "topic") async throws {
        try await handleWCV2ConnectionRequestAndWait(topic: topic)
        
        mockWCServiceV2.pSessionProposalPublisher.send((getWC2SessionProposal(topic: topic), nil))
        try await waitFor(interval: 0.1)
    }
    
    func getConnectionTarget() -> (UDWallet, DomainItem) {
        (createLocallyGeneratedBackedUpUDWallet(), createMockDomainItem())
    }
    
    func getWCV2URI(topic: String) -> WalletConnectSign.WalletConnectURI {
        .init(topic: topic, symKey: "symKey", relay: .init(protocol: "", data: nil))
    }
    
    func getWCV2ConnectionRequest(topic: String) -> WCRequest {
        WCRequest.connectWallet(WalletConnectServiceV2.ConnectWalletRequest(uri: getWCV2URI(topic: topic)))
    }
    
    func getWC2SessionProposal(topic: String = "topic") -> SessionV2.Proposal {
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
        
        let redirect = AppMetadata.Redirect(native: "", universal: nil)
        let appMetaData = WalletConnectSign.AppMetadata(name: "name", description: "des", url: "https://g.com", icons: [], redirect: redirect)
        let participantClone = ParticipantClone(publicKey: "key", metadata: appMetaData)
        let sessionProposalClone = SessionProposalClone(relays: [],
                                                        proposer: participantClone,
                                                        requiredNamespaces: [:])
        let proposalClone = ProposalClone(id: topic,
                                          pairingTopic: topic,
                                          proposer: appMetaData,
                                          requiredNamespaces: [:],
                                          proposal: sessionProposalClone)
        let data = proposalClone.jsonData()!
        
        let proposal: SessionV2.Proposal = SessionV2.Proposal.genericObjectFromData(data)!
        return proposal
    }
    
    func callWC2Handler(requestType: WalletConnectRequestType) {
        mockWCServiceV2.pSessionRequestPublisher.send((Request(topic: "topic",
                                                              method: requestType.rawValue,
                                                              params: WCAnyCodable(""),
                                                              chainId: Blockchain("eip155:1")!),
                                                       VerifyContext(origin: nil,
                                                                     validation: .valid)))
    }
    
    func awaitForLongerThanConnectionTimeout() async throws {
        try await waitFor(interval: Constants.wcConnectionTimeout * 1.2)
    }
}

private final class MockWCServiceV2: WalletConnectV2RequestHandlingServiceProtocol, WalletConnectV2PublishersProvider {
    
    private(set) var pSessionProposalPublisher = PassthroughSubject<(proposal: SessionV2.Proposal, context: WalletConnectSign.VerifyContext?), Never>()
    var sessionProposalPublisher: AnyPublisher<(proposal: SessionV2.Proposal, context: WalletConnectSign.VerifyContext?), Never> { pSessionProposalPublisher.eraseToAnyPublisher() }
    
    private(set) var pSessionRequestPublisher = PassthroughSubject<(request: WalletConnectSign.Request, context: WalletConnectSign.VerifyContext?), Never>()
    var sessionRequestPublisher: AnyPublisher<(request: WalletConnectSign.Request, context: WalletConnectSign.VerifyContext?), Never> { pSessionRequestPublisher.eraseToAnyPublisher() }
    
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
    
    func handleSendTx(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        let response = try await getResponse()
        return response
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
    
    func handleSignTypedData_v4(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        try await getResponse()
    }
    
    func getResponse() async throws -> JSONRPC.RPCResult {
        if let errorToFail {
            throw errorToFail
        }
        return .response(WCAnyCodable(""))
    }
}

// MARK: - WalletConnectUIErrorHandler
private final class MockWalletConnectUIErrorHandler: WalletConnectUIErrorHandler {
    
    private(set) var didFailToConnect = false
    
    func didFailToConnect(with error: domains_manager_ios.WalletConnectRequestError) async {
        didFailToConnect = true
    }
    
    func dismissLoadingPageIfPresented() async { }
}

// MARK: - WalletConnectServiceConnectionListener
private final class MockWCServiceListener: WalletConnectServiceConnectionListener {
    
    var didConnectCalled: Bool { didConnectCalledCount > 0 }
    private(set) var didConnectCalledCount = 0
    private(set) var didDisconnectCalled = false
    private(set) var didCompletionAttemptCalled = false
    var didHandleExternalWCRequest: Bool { didHandleExternalWCRequestCount > 0 }
    private(set) var didHandleExternalWCRequestCount = 0
    
    func didConnect(to app: domains_manager_ios.UnifiedConnectAppInfo) {
        didConnectCalledCount += 1
    }
    
    func didDisconnect(from app: domains_manager_ios.UnifiedConnectAppInfo) {
        didDisconnectCalled = true
    }
    
    func didCompleteConnectionAttempt() {
        didCompletionAttemptCalled = true
    }
    
    func didHandleExternalWCRequestWith(result: WCExternalRequestResult) {
        didHandleExternalWCRequestCount += 1
    }
}
