//
//  DeepLinksServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 20.02.2023.
//

import XCTest
@testable import domains_manager_ios

final class DeepLinksServiceTests: BaseTestClass {
    
    private var mockExternalEventsService: PrivateMockExternalEventsService!
    private var mockCoreAppCoordinator: MockCoreAppCoordinator!
    private var deepLinksServiceListener: PrivateDeepLinksListener!
    private var deepLinksService: DeepLinksService!
    
    let deepLink = "https://unstoppabledomains.com/mobile"
    lazy var wcDeepLink = "\(deepLink)/wc"
    let wcUri = "wc:c873dde5-f55e-48aa-9a1d-5e4155f03e88@1?bridge=https%3A%2F%2Fa.bridge.walletconnect.org&key=23507592f17d72ef50c3691e4d665cbfa0f2e95601cb1261ab6dc8070875c825"
    lazy var wcConnectionDeepLink = "\(wcDeepLink)?uri=\(wcUri)"
    lazy var wcConnectionDeepLink2 = "\(deepLink)?uri=\(wcUri)"
        
    override func setUp() async throws {
        try await super.setUp()
        
        mockExternalEventsService = PrivateMockExternalEventsService()
        deepLinksServiceListener = PrivateDeepLinksListener()
        mockCoreAppCoordinator = await MockCoreAppCoordinator()
        deepLinksService = DeepLinksService(externalEventsService: mockExternalEventsService,
                                            coreAppCoordinator: mockCoreAppCoordinator)
        deepLinksService.addListener(deepLinksServiceListener)
    }
 
    func testWCConnectionDeepLinkHandled() async throws {
        try await handleWCLink(wcConnectionDeepLink)
    }
    
    func testWCConnectionDeepLink2Handled() async throws {
        try await handleWCLink(wcConnectionDeepLink2)
    }
    
    private func handleWCLink(_ link: String) async throws {
        let url = URL(string: link)!
        deepLinksService.handleUniversalLink(url, receivedState: .foreground)
        
        let expectedWCUri = URL(string: "wc:c873dde5-f55e-48aa-9a1d-5e4155f03e88@1?bridge=https://a.bridge.walletconnect.org")!
        let expectedEvent = ExternalEvent.wcDeepLink(expectedWCUri)
        
        // Test EventsService handling WC URL
        XCTAssertEqual(expectedEvent, mockExternalEventsService.receivedEvent)
        XCTAssertEqual(nil, deepLinksServiceListener.receivedEvent)
        
        // Test user redirected back to the source app when request confirmed
        try await XCTAssertFalseAsync(await mockCoreAppCoordinator.didGoBackToPreviousAppCalled)
        try await waitFor(interval: 0.1)
        try await XCTAssertTrueAsync(await mockCoreAppCoordinator.didGoBackToPreviousAppCalled)
    }
    
    func testWCRequestDeepLinkHandled() async throws {
        let url = URL(string: wcDeepLink)!
        deepLinksService.handleUniversalLink(url, receivedState: .foreground)
        
        // Test no extra events passed
        XCTAssertEqual(nil, mockExternalEventsService.receivedEvent)
        XCTAssertEqual(nil, deepLinksServiceListener.receivedEvent)

        // Test user redirected back to the source app when request cancelled
        try await XCTAssertFalseAsync(await mockCoreAppCoordinator.didGoBackToPreviousAppCalled)
        deepLinksService.didCompleteConnectionAttempt()
        try await waitFor(interval: 0.1)
        try await XCTAssertTrueAsync(await mockCoreAppCoordinator.didGoBackToPreviousAppCalled)
    }
    
    func testUDMintDomainsDeepLinkHandled() {
        let email = "oleg@unstoppabledomains.com"
        let code = "8FSZDS"
        let mintDomainsDeepLink = "\(deepLink)?operation=MobileMintDomains&email=\(email)&code=\(code)"
        let url = URL(string: mintDomainsDeepLink)!
        
        deepLinksService.handleUniversalLink(url, receivedState: .foreground)
        
        // Test listeners notified about received event
        XCTAssertEqual(nil, mockExternalEventsService.receivedEvent)
        XCTAssertEqual(.mintDomainsVerificationCode(email: email, code: code), deepLinksServiceListener.receivedEvent)
    }
    
    /// Import wallets currently not supported. Should not be unexpected callbacks when received
    func testUDImportWalletsDeepLinkHandled() {
        let mintDomainsDeepLink = "\(deepLink)?operation=MobileImportWallets"
        let url = URL(string: mintDomainsDeepLink)!
        
        deepLinksService.handleUniversalLink(url, receivedState: .foreground)
        
        // Test no extra events passed
        XCTAssertEqual(nil, mockExternalEventsService.receivedEvent)
        XCTAssertEqual(nil, deepLinksServiceListener.receivedEvent)
    }
    
    func testEmptyDeepLinkReceived() {
        let url = URL(string: deepLink)!
        
        deepLinksService.handleUniversalLink(url, receivedState: .foreground)
        
        // Test no extra events passed
        XCTAssertEqual(nil, mockExternalEventsService.receivedEvent)
        XCTAssertEqual(nil, deepLinksServiceListener.receivedEvent)
    }
    
    func testUnknownUDDeepLinkReceived() {
        let unknownLink = "\(deepLink)?operation=UnknownOperation"
        let url = URL(string: unknownLink)!
        
        deepLinksService.handleUniversalLink(url, receivedState: .foreground)
        
        // Test no extra events passed
        XCTAssertEqual(nil, mockExternalEventsService.receivedEvent)
        XCTAssertEqual(nil, deepLinksServiceListener.receivedEvent)
    }
    
    func testInvalidUDDeepLinkReceived() {
        let invalidLink = "not_url"
        let url = URL(string: invalidLink)!
        
        deepLinksService.handleUniversalLink(url, receivedState: .foreground)
        
        // Test no extra events passed
        XCTAssertEqual(nil, mockExternalEventsService.receivedEvent)
        XCTAssertEqual(nil, deepLinksServiceListener.receivedEvent)
    }
    
    func testInvalidWCDeepLinkReceived() {
        let invalidLink = wcConnectionDeepLink.replacingOccurrences(of: "uri=wc:c873dde5", with: "")
        let url = URL(string: invalidLink)!
        
        deepLinksService.handleUniversalLink(url, receivedState: .foreground)
        
        // Test no extra events passed
        XCTAssertEqual(nil, mockExternalEventsService.receivedEvent)
        XCTAssertEqual(nil, deepLinksServiceListener.receivedEvent)
    }
}

private final class PrivateDeepLinksListener: DeepLinkServiceListener {
    private(set) var receivedEvent: DeepLinkEvent?
    
    func didReceiveDeepLinkEvent(_ event: DeepLinkEvent,
                                 receivedState: ExternalEventReceivedState) {
        self.receivedEvent = event
    }
}

private final class PrivateMockExternalEventsService: ExternalEventsServiceProtocol {
    private(set) var receivedEvent: ExternalEvent?
    func receiveEvent(_ event: domains_manager_ios.ExternalEvent, receivedState: domains_manager_ios.ExternalEventReceivedState) {
        receivedEvent = event
    }
    
    func checkPendingEvents() {
        
    }
    
    func addListener(_ listener: domains_manager_ios.ExternalEventsServiceListener) {
        
    }
    
    func removeListener(_ listener: domains_manager_ios.ExternalEventsServiceListener) {
        
    }
}

private final class MockCoreAppCoordinator: CoreAppCoordinatorProtocol {
    func didRegisterShakeDevice() {
        
    }
    
    func askToReconnectExternalWallet(_ walletDisplayInfo: domains_manager_ios.WalletDisplayInfo) async -> Bool {
        false
    }
    
    func showExternalWalletDidNotRespondPullUp(for connectingWallet: domains_manager_ios.WCWalletsProvider.WalletRecord) async {
        
    }
    
    private(set) var didGoBackToPreviousAppCalled = false
    
    func startWith(window: UIWindow) {
        
    }
    
    func showOnboarding(_ flow: domains_manager_ios.OnboardingNavigationController.OnboardingFlow) {
        
    }
    
    func showHome(mintingState: domains_manager_ios.DomainsCollectionMintingState) {
        
    }
    
    func showAppUpdateRequired() {
        
    }
    
    func setKeyWindow() {
        
    }
    func isActiveState(_ state: AppCoordinationState) -> Bool { false }
    func goBackToPreviousApp() -> Bool {
        didGoBackToPreviousAppCalled = true
        return true
    }
        
    func didFailToConnect(with error: domains_manager_ios.WalletConnectRequestError) {
        
    }
    
    func didReceiveUnsupported(_ wcRequestMethodName: String) {
        
    }
    
    func didDisconnect(walletDisplayInfo: domains_manager_ios.WalletDisplayInfo) {
        
    }
    
    func handle(uiFlow: domains_manager_ios.ExternalEventUIFlow) async throws {
        
    }
}
