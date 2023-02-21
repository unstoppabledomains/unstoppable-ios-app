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
    private var deepLinksService: DeepLinksService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockExternalEventsService = PrivateMockExternalEventsService()
        mockCoreAppCoordinator = await MockCoreAppCoordinator()
        deepLinksService = DeepLinksService(externalEventsService: mockExternalEventsService,
                                            coreAppCoordinator: mockCoreAppCoordinator)
    }
 
    func testWCDeepLinkHandled() async throws {
        let wcUri = "wc%3Ac873dde5-f55e-48aa-9a1d-5e4155f03e88%401%3Fbridge%3Dhttps%253A%252F%252Fa.bridge.walletconnect.org%26key%3D23507592f17d72ef50c3691e4d665cbfa0f2e95601cb1261ab6dc8070875c825"
        let wcDeepLink = "https://unstoppabledomains.com/mobile/wc?uri="
        let url = URL(string: wcDeepLink)!
        deepLinksService.handleUniversalLink(url, receivedState: .foreground)
        
        let expectedEvent = ExternalEvent.wcDeepLink(url)
        XCTAssertEqual(expectedEvent, mockExternalEventsService.receivedEvent)
        try await XCTAssertFalseAsync(await mockCoreAppCoordinator.didGoBackToPreviousAppCalled)
        
        deepLinksService.didConnect(to: nil)
        try await waitFor(interval: 0.1)
        try await XCTAssertTrueAsync(await mockCoreAppCoordinator.didGoBackToPreviousAppCalled)
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
    
    func goBackToPreviousApp() -> Bool {
        didGoBackToPreviousAppCalled = true
        return true
    }
    
    func getConfirmationToConnectServer(config: domains_manager_ios.WCRequestUIConfiguration) async throws -> domains_manager_ios.WalletConnectService.ConnectionUISettings {
        throw NSError(domain: "-1", code: -1)
    }
    
    func didFailToConnect(with error: domains_manager_ios.WalletConnectService.Error) {
        
    }
    
    func didReceiveUnsupported(_ wcRequestMethodName: String) {
        
    }
    
    func didDisconnect(walletDisplayInfo: domains_manager_ios.WalletDisplayInfo) {
        
    }
    
    func handle(uiFlow: domains_manager_ios.ExternalEventUIFlow) async throws {
        
    }
}
