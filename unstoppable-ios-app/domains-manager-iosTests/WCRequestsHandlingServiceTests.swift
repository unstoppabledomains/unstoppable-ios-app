//
//  WCRequestsHandlingServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 23.02.2023.
//

import Foundation

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
    
    func testWCV1ConnectionRequestHandled() async throws {
        verifyInitialState()
        try await wcRequestsHandlingService.handleWCRequest(wcV1ConnectionRequest(), target: getConnectionTarget())
        try await waitFor(interval: 0.1)
        
        // Check request passed to service
        XCTAssertNotNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        
        mockWCServiceV1.callCompletion(result: .success(nil))
        
        // Check listeners notified correctly
        XCTAssertTrue(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
    }
    
    private func verifyInitialState() {
        XCTAssertNil(mockWCServiceV1.completion)
        XCTAssertNil(mockWCServiceV2.completion)
        XCTAssertEqual(0, mockWCServiceV1.responseSentCount)
        XCTAssertEqual(0, mockWCServiceV2.responseSentCount)
        XCTAssertFalse(mockWCServiceV1.didCallConnectionTimeout)
        XCTAssertFalse(mockWCServiceV2.didCallConnectionTimeout)
        
        XCTAssertFalse(mockListener.didConnectCalled)
        XCTAssertFalse(mockListener.didDisconnectCalled)
        XCTAssertFalse(mockListener.didCompletionAttemptCalled)
    }
}

// MARK: - Private methods
private extension WCRequestsHandlingServiceTests {
    func wcV1URL() -> WalletConnectSwift.WCURL {
        .init(topic: "topic", bridgeURL: URL(string: "https://g.com")!, key: "key")
    }
    
    func wcV1ConnectionRequest() -> WCRequest {
        WCRequest.connectWallet(.version1(wcV1URL()))
    }
    
    func getConnectionTarget() -> (UDWallet, DomainItem) {
        (createLocallyGeneratedBackedUpUDWallet(), createMockDomainItem())
    }
}

private final class MockWCServiceV1: WalletConnectV1RequestHandlingServiceProtocol {
    
    // Mock properties
    var errorToFail: Error?
    private(set) var didCallConnectionTimeout = false
    private(set) var completion: WCConnectionResultCompletion?
    private(set) var responseSentCount = 0
    
    func callCompletion(result: WCConnectionResult) {
        completion?(result)
        completion = nil
    }
    
    // WalletConnectV1RequestHandlingServiceProtocol properties
    var appDisconnectedCallback: domains_manager_ios.WCAppDisconnectedCallback?
    var willHandleRequestCallback: domains_manager_ios.EmptyCallback?
    
    func registerRequestHandler(_ requestHandler: WalletConnectSwift.RequestHandler) { }
    
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

private final class MockWCServiceV2: WalletConnectV2RequestHandlingServiceProtocol {
    
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
    
    func pairClient(uri: WalletConnectUtils.WalletConnectURI) async throws {
        
    }
    
    func handleConnectionProposal(_ proposal: domains_manager_ios.WC2ConnectionProposal,
                                  completion: @escaping domains_manager_ios.WCConnectionResultCompletion) {
        self.completion = completion
    }
    
    func sendResponse(_ response: JSONRPC.RPCResult, toRequest request: WalletConnectSign.Request) async throws {
        
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
    
    func didConnect(to app: domains_manager_ios.PushSubscriberInfo?) {
        didConnectCalled = true
    }
    
    func didDisconnect(from app: domains_manager_ios.PushSubscriberInfo?) {
        didDisconnectCalled = true
    }
    
    func didCompleteConnectionAttempt() {
        didCompletionAttemptCalled = true
    }
}
