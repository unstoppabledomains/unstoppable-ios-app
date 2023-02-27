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
        try await handleWCV1ConnectionRequestAndWait()
        
        // Check request passed to service
        XCTAssertNotNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        
        mockWCServiceV1.callCompletion(result: result)
        try await waitFor(interval: 0.1)
    }
    
    func testWCV1ConnectionRequestHandled() async throws {
        verifyInitialState()
        try await makeWC1RequestWith(result: .success(createV1UnifiedConnectAppInfo()))
        
        // Check listeners notified correctly
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertTrue(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequest)
    }
    
    func testWCV1ConnectionRequestFailed() async throws {
        verifyInitialState()
        try await makeWC1RequestWith(result: .failure(WalletConnectRequestError.failedConnectionRequest))
        
        // Check listeners notified correctly
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertTrue(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequest)
        XCTAssertTrue(mockUIErrorHandler.didFailToConnect)
    }
    
    func testWCV1ConnectionRequestUserCancelled() async throws {
        verifyInitialState()
        try await makeWC1RequestWith(result: .failure(uiCancelledError))
        
        // Check listeners notified correctly
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertTrue(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
        
    // MARK: - V1 Sign tests
    private func makeWC1SignRequest() async throws {
        callWC1Handler(requestType: .personalSign)
        try await waitFor(interval: 0.1)
    }

    func testWC1SignRequestHandled() async throws {
        verifyInitialState()
        try await makeWC1SignRequest()
        XCTAssertEqual(1, mockWCServiceV1.responseSentCount)
        XCTAssertEqual(0, mockWCServiceV2.responseSentCount)
        XCTAssertTrue(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    func testWC1SignRequestFailed() async throws {
        verifyInitialState()
        mockWCServiceV1.errorToFail = WalletConnectRequestError.failedConnectionRequest
        try await makeWC1SignRequest()
        XCTAssertEqual(1, mockWCServiceV1.responseSentCount)
        XCTAssertEqual(0, mockWCServiceV2.responseSentCount)
        XCTAssertTrue(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertTrue(mockUIErrorHandler.didFailToConnect)
    }
    
    func testWC1SignRequestCancelled() async throws {
        verifyInitialState()
        mockWCServiceV1.errorToFail = uiCancelledError
        try await makeWC1SignRequest()
        XCTAssertEqual(1, mockWCServiceV1.responseSentCount)
        XCTAssertEqual(0, mockWCServiceV2.responseSentCount)
        XCTAssertTrue(mockListener.didHandleExternalWCRequest)
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
        try await handleWCV2ConnectionRequestAndWait()
        
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
        verifyInitialState()
        try await makeWC2RequestWith(result: .success(createV1UnifiedConnectAppInfo()))
        
        // Check listeners notified correctly
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertTrue(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    func testWCV2ConnectionRequestFailed() async throws {
        verifyInitialState()
        try await makeWC2RequestWith(result: .failure(WalletConnectRequestError.failedConnectionRequest))
        
        // Check listeners notified correctly
        XCTAssertNil(mockWCServiceV1.completion)
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
        XCTAssertNil(mockWCServiceV1.completion)
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
        XCTAssertEqual(0, mockWCServiceV1.responseSentCount)
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
        XCTAssertEqual(0, mockWCServiceV1.responseSentCount)
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
        XCTAssertEqual(0, mockWCServiceV1.responseSentCount)
        XCTAssertEqual(1, mockWCServiceV2.responseSentCount)
        XCTAssertTrue(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
}

// MARK: - Disconnect
extension WCRequestsHandlingServiceTests {
    func testWCV1Disconnected() async throws {
        verifyInitialState()
        
        mockWCServiceV1.appDisconnectedCallback?(createV1UnifiedConnectAppInfo())
        try await waitFor(interval: 0.1)
        
        XCTAssertFalse(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertTrue(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
    }
    
    func testWCV2Disconnected() async throws {
        verifyInitialState()
        
        mockWCServiceV2.appDisconnectedCallback?(createV1UnifiedConnectAppInfo())
        try await waitFor(interval: 0.1)
        
        XCTAssertFalse(mockListener.didHandleExternalWCRequest)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertTrue(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
    }
}

// MARK: - Requests queuing
extension WCRequestsHandlingServiceTests {
    func testSameRequestsHandled() async throws {
        verifyInitialState()
        
        // Add first request
        try await handleWCV1ConnectionRequestAndWait()
        // Add second request before first is resolved
        try await handleWCV1ConnectionRequestAndWait()
      
        // Complete first request
        mockWCServiceV1.callCompletion(result: .success(createV1UnifiedConnectAppInfo()))
        try await waitFor(interval: 0.1)
        XCTAssertEqual(mockListener.didConnectCalledCount, 1)
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
    }
    
    func testTwoWC1ConnectRequestsHandled() async throws {
        verifyInitialState()
        
        // Add first request
        try await handleWCV1ConnectionRequestAndWait()
        
        // Check request passed to service
        XCTAssertNotNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertFalse(mockListener.didConnectCalled)
        
        // Add second request before first is resolved
        try await handleWCV1ConnectionRequestAndWait(topic: "topic2")
        XCTAssertNotNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertFalse(mockListener.didConnectCalled)
        
        // Complete first request
        mockWCServiceV1.callCompletion(result: .success(createV1UnifiedConnectAppInfo()))
        try await waitFor(interval: 0.1)
        XCTAssertEqual(mockListener.didConnectCalledCount, 1)
        XCTAssertNotNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        
        // Complete second request
        mockWCServiceV1.callCompletion(result: .success(createV1UnifiedConnectAppInfo()))
        try await waitFor(interval: 0.1)
        XCTAssertEqual(mockListener.didConnectCalledCount, 2)
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
    }
    
    func testTwoWC1SignRequestsHandled() async throws {
        verifyInitialState()
        
        callWC1Handler(requestType: .personalSign)
        callWC1Handler(requestType: .personalSign)
        try await waitFor(interval: 0.1)

        XCTAssertEqual(2, mockWCServiceV1.responseSentCount)
        XCTAssertEqual(0, mockWCServiceV2.responseSentCount)
        XCTAssertEqual(2, mockListener.didHandleExternalWCRequestCount)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    func testMixedWC1RequestsHandled() async throws {
        verifyInitialState()
        
        callWC1Handler(requestType: .personalSign)

        // Add first request
        try await handleWCV1ConnectionRequestAndWait()
        try await waitFor(interval: 0.1)
        
        mockWCServiceV1.callCompletion(result: .failure(WalletConnectRequestError.failedConnectionRequest))
        try await waitFor(interval: 0.1)
     
        XCTAssertEqual(1, mockWCServiceV1.responseSentCount)
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertTrue(mockListener.didCompletionAttemptCalled)
        XCTAssertTrue(mockUIErrorHandler.didFailToConnect)
    }
    
    func testMixedWCVersionsRequestsHandled() async throws {
        verifyInitialState()
        
        // Add first WC2 request
        try await handleWCV2ConnectionRequestAndProposalAndWait()
        
        // Check request passed to service
        XCTAssertNotNil(mockWCServiceV2.completion)
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertFalse(mockListener.didConnectCalled)
        
        // Add second WC1 request
        try await handleWCV1ConnectionRequestAndWait()
        
        // Check it is not passed, waiting for its turn
        XCTAssertNotNil(mockWCServiceV2.completion)
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertFalse(mockListener.didConnectCalled)
        
        // Complete first WC2 request
        mockWCServiceV2.callCompletion(result: .success(createV1UnifiedConnectAppInfo()))
        try await waitFor(interval: 0.1)
        
        // Check WC2 request handled. Check WC1 turn now
        XCTAssertEqual(mockListener.didConnectCalledCount, 1)
        XCTAssertNotNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        
        // Complete second WC1 request
        mockWCServiceV1.callCompletion(result: .success(createV1UnifiedConnectAppInfo()))
        try await waitFor(interval: 0.1)
        
        // Check WC1 request handled
        XCTAssertEqual(mockListener.didConnectCalledCount, 2)
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
    }
}

// MARK: - Request timeout
extension WCRequestsHandlingServiceTests {
    func testWCV1RequestTimeout() async throws {
        verifyInitialState()
        
        try await handleWCV1ConnectionRequestAndWait()
        try await awaitForLongerThanConnectionTimeout()
        
        XCTAssertTrue(mockWCServiceV1.didCallConnectionTimeout)
        XCTAssertTrue(mockWCServiceV2.didCallConnectionTimeout)
    }
    
    func testWCV2RequestTimeout() async throws {
        verifyInitialState()
        
        try await handleWCV2ConnectionRequestAndProposalAndWait()
        try await awaitForLongerThanConnectionTimeout()
        
        XCTAssertTrue(mockWCServiceV1.didCallConnectionTimeout)
        XCTAssertTrue(mockWCServiceV2.didCallConnectionTimeout)
    }
    
    func testRequestTimeoutAfterExpecting() async throws {
        verifyInitialState()
        wcRequestsHandlingService.expectConnection()
        XCTAssertFalse(mockWCServiceV1.didCallConnectionTimeout)
        XCTAssertFalse(mockWCServiceV2.didCallConnectionTimeout)
        
        try await awaitForLongerThanConnectionTimeout()
        
        XCTAssertTrue(mockWCServiceV1.didCallConnectionTimeout)
        XCTAssertTrue(mockWCServiceV2.didCallConnectionTimeout)
    }
}

// MARK: - Private methods
private extension WCRequestsHandlingServiceTests {
    var uiCancelledError: Error { WalletConnectUIError.cancelled }
    
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
        XCTAssertFalse(mockListener.didHandleExternalWCRequest)
        
        XCTAssertFalse(mockUIErrorHandler.didFailToConnect)
    }
    
    func getWCV1URL(topic: String) -> WalletConnectSwift.WCURL {
        .init(topic: topic, bridgeURL: URL(string: "https://g.com")!, key: "key")
    }
    
    func getWCV1ConnectionRequest(topic: String) -> WCRequest {
        WCRequest.connectWallet(.version1(getWCV1URL(topic: topic)))
    }
    
    func handleWCV1ConnectionRequestAndWait(topic: String = "topic") async throws {
        try await wcRequestsHandlingService.handleWCRequest(getWCV1ConnectionRequest(topic: topic), target: getConnectionTarget())
        try await waitFor(interval: 0.1)
    }
    
    func handleWCV2ConnectionRequestAndWait(topic: String = "topic") async throws {
        try await wcRequestsHandlingService.handleWCRequest(getWCV2ConnectionRequest(topic: topic), target: getConnectionTarget())
        try await waitFor(interval: 0.1)
    }
    
    func handleWCV2ConnectionRequestAndProposalAndWait(topic: String = "topic") async throws {
        try await handleWCV2ConnectionRequestAndWait(topic: topic)
        
        mockWCServiceV2.pSessionProposalPublisher.send(getWC2SessionProposal(topic: topic))
        try await waitFor(interval: 0.1)
    }
    
    func getConnectionTarget() -> (UDWallet, DomainItem) {
        (createLocallyGeneratedBackedUpUDWallet(), createMockDomainItem())
    }
    
    func getWCV2URI(topic: String) -> WalletConnectSign.WalletConnectURI {
        .init(topic: topic, symKey: "symKey", relay: .init(protocol: "", data: nil))
    }
    
    func getWCV2ConnectionRequest(topic: String) -> WCRequest {
        WCRequest.connectWallet(.version2(getWCV2URI(topic: topic)))
    }
    
    func getWC2SessionProposal(topic: String = "topic") -> WalletConnectSign.Session.Proposal {
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
        let proposalClone = ProposalClone(id: topic,
                                          pairingTopic: topic,
                                          proposer: appMetaData,
                                          requiredNamespaces: [:],
                                          proposal: sessionProposalClone)
        let data = proposalClone.jsonData()!
        
        let proposal: WalletConnectSign.Session.Proposal = WalletConnectSign.Session.Proposal.genericObjectFromData(data)!
        return proposal
    }
    
    func callWC1Handler(requestType: WalletConnectRequestType, topic: String = "topic") {
        let handlers = mockWCServiceV1.requestHandlers as! [WalletConnectV1SignTransactionHandler]
        let handler = handlers.first(where: { $0.requestType == requestType })!
        
        let request = WalletConnectSwift.Request(url: getWCV1URL(topic: topic), method: requestType.rawValue)
        handler.handle(request: request)
    }
    
    func callWC2Handler(requestType: WalletConnectRequestType) {
        mockWCServiceV2.pSessionRequestPublisher.send(.init(topic: "topic", method: requestType.rawValue, params: AnyCodable(""), chainId: .init("eip155:1")!))
    }
    
    func awaitForLongerThanConnectionTimeout() async throws {
        try await waitFor(interval: Constants.wcConnectionTimeout * 1.2)
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
