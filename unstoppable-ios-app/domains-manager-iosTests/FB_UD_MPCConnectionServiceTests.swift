//
//  FB_UD_MPCConnectionServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 20.05.2024.
//

import XCTest
@testable import domains_manager_ios

final class FB_UD_MPCConnectionServiceTests: BaseTestClass, FB_UD_MPC.FireblocksConnectorBuilder {
    
    private let deviceId = "device-id"
    private var mpcMetadata: MPCWalletMetadata!
    
    private var connector: MockFireblocksConnector!
    private var networkService: MockNetworkService!
    private var storage: MockMPCWalletsDataStorage!
    private var udWalletsService = TestableUDWalletsService()
    private var uiHandler: MockMPCWalletUIHandler!
    private var mpcConnectionService: FB_UD_MPC.MPCConnectionService!

    override func setUp() async throws {
        try await super.setUp()
        
        let metadata = FB_UD_MPC.UDWalletMetadata(deviceId: deviceId).jsonData()
        mpcMetadata = MPCWalletMetadata(provider: .fireblocksUD, metadata: metadata)
        
        connector = MockFireblocksConnector()
        networkService = MockNetworkService()
        networkService.deviceId = deviceId
        storage = MockMPCWalletsDataStorage()
        uiHandler = await MockMPCWalletUIHandler()
        udWalletsService = TestableUDWalletsService()
        mpcConnectionService = .init(connectorBuilder: self,
                                     networkService: networkService,
                                     walletsDataStorage: storage,
                                     udWalletsService: udWalletsService, 
                                     uiHandler: uiHandler)
    }
    
    func buildBootstrapMPCConnector(deviceId: String, accessToken: String) throws -> any FB_UD_MPC.FireblocksConnectorProtocol {
        connector
    }
    
    func buildWalletMPCConnector(wallet: FB_UD_MPC.ConnectedWalletDetails, authTokenProvider: any FB_UD_MPC.WalletAuthTokenProvider) throws -> any FB_UD_MPC.FireblocksConnectorProtocol {
        connector
    }
}

// MARK: - Tokens
extension FB_UD_MPCConnectionServiceTests {
    func testGetAuthTokens_NotExpiredAccessToken() async throws {
        let tokens = MPCEntitiesBuilder.createAuthTokens()
        setTokensToStorage(tokens)
        
        let _ = try await mpcConnectionService.getBalancesFor(walletMetadata: mpcMetadata)
        XCTAssertEqual(networkService.getAccountsCalls, [tokens.accessToken.jwt])
        XCTAssertEqual(networkService.refreshTokenCalls, [])
        XCTAssertEqual(networkService.refreshBootstrapCalls, [])
    }
    
    func testGetAuthTokens_ExpiredAccessToken_ValidRefreshToken() async throws {
        let tokens = MPCEntitiesBuilder.createAuthTokens(accessTokenExpired: true)
        setTokensToStorage(tokens)
        
        let _ = try await mpcConnectionService.getBalancesFor(walletMetadata: mpcMetadata)
        XCTAssertEqual(networkService.refreshTokenCalls, [tokens.refreshToken.jwt])
        
        let newTokens = storage.authTokens[deviceId]!
        XCTAssertEqual(networkService.getAccountsCalls, [newTokens.accessToken.jwt])
        XCTAssertEqual(networkService.refreshBootstrapCalls, [])
    }
   
    func testGetAuthTokens_AllTokensExpired() async throws {
        // Setup
        let tokens = MPCEntitiesBuilder.createAuthTokens(accessTokenExpired: true,
                                                         refreshTokenExpired: true,
                                                         bootstrapTokenExpired: true)
        setTokensToStorage(tokens)
        
        do {
            let _ = try await mpcConnectionService.getBalancesFor(walletMetadata: mpcMetadata)
            assertionFailure("Should fail")
        } catch {
            XCTAssertEqual(networkService.getAccountsCalls, [])
            XCTAssertEqual(networkService.refreshTokenCalls, [])
            XCTAssertEqual(networkService.refreshBootstrapCalls, [])
        }
    }
    
    func testGetAuthTokens_SimultaneousRequests() async throws {
        let tokens = MPCEntitiesBuilder.createAuthTokens(accessTokenExpired: true)
        setTokensToStorage(tokens)
        
        let mpcMetadata = self.mpcMetadata!
        let numberOfSimReqs = 5
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    let _ = try await self.mpcConnectionService.getBalancesFor(walletMetadata: mpcMetadata)
                }
            }
            
            for try await _ in group { }
        }
        
        XCTAssertEqual(networkService.refreshTokenCalls, [tokens.refreshToken.jwt])
        
        let newTokens = storage.authTokens[deviceId]!
        XCTAssertEqual(networkService.getAccountsCalls, Array(repeating: newTokens.accessToken.jwt, count: numberOfSimReqs))
    }
}

// MARK: - Private methods
private extension FB_UD_MPCConnectionServiceTests {
    func setTokensToStorage(_ tokens: FB_UD_MPC.AuthTokens) {
        storage.authTokens[deviceId] = tokens
        storage.accountDetails[deviceId] = MPCEntitiesBuilder.createAccountDetails(deviceId: deviceId)
    }
}

private struct MPCEntitiesBuilder {
    static func createMockJWToken(value: String = UUID().uuidString,
                           isExpired: Bool) -> JWToken {
        JWToken(header: .init(alg: "", typ: ""),
                body: .init(issueDate: Date().addingTimeInterval(-100),
                            expirationDate: Date().addingTimeInterval(isExpired ? -5 : 100),
                            aud: "",
                            iss: ""),
                signature: "",
                jwt: value)
    }
    
    static func createAuthTokens(accessTokenExpired: Bool = false,
                          refreshTokenExpired: Bool = false,
                          bootstrapTokenExpired: Bool = false) -> FB_UD_MPC.AuthTokens {
        let accessToken = createMockJWToken(isExpired: accessTokenExpired)
        let refreshToken = createMockJWToken(isExpired: refreshTokenExpired)
        let bootstrapToken = createMockJWToken(isExpired: bootstrapTokenExpired)
        return .init(accessToken: accessToken,
                     refreshToken: refreshToken,
                     bootstrapToken: bootstrapToken)
    }
    
    static func createAccountAsset() -> FB_UD_MPC.WalletAccountAsset {
        let blockchainAsset = FB_UD_MPC.BlockchainAsset(type: "1",
                                                        id: "1",
                                                        name: "Ethereum",
                                                        symbol: "ETH",
                                                        blockchain: .init(id: "1", name: "ETH"))
        let asset = FB_UD_MPC.WalletAccountAsset(type: "1",
                                                 id: "1",
                                                 address: "1",
                                                 balance: nil,
                                                 blockchainAsset: blockchainAsset)
        return asset
    }
    
    static func createAccountDetails(deviceId: String) -> FB_UD_MPC.ConnectedWalletAccountsDetails {
        let account = FB_UD_MPC.WalletAccount(type: "1", id: "1")
        let asset = createAccountAsset()
        let accountWithAsset = FB_UD_MPC.WalletAccountWithAssets(account: account,
                                                                 assets: [asset])
        return .init(deviceId: deviceId,
                     firstAccount: accountWithAsset, accounts: [accountWithAsset])
    }
}

private final class MockFireblocksConnector: FB_UD_MPC.FireblocksConnectorProtocol {
    func requestJoinExistingWallet() async throws -> String {
        ""
    }
    
    func stopJoinWallet() {
        
    }
    
    func waitForKeyIsReady() async throws {
        
    }
    
    func signTransactionWith(txId: String) async throws {
        
    }
    
    func getLogsURLs() -> URL? {
        nil
    }
}

private final class MockNetworkService: FB_UD_MPC.MPCConnectionNetworkService, FailableService {
    var shouldFail: Bool = false
    var deviceId: String = ""
    let queue = DispatchQueue(label: "MockNetworkService")
    
    func sendBootstrapCodeTo(email: String) async throws {
        try failIfNeeded()
    }
    
    func submitBootstrapCode(_ code: String) async throws -> FB_UD_MPC.BootstrapCodeSubmitResponse {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func authNewDeviceWith(requestId: String, recoveryPhrase: String, accessToken: String) async throws {
        try failIfNeeded()
    }
    
    func initTransactionWithNewKeyMaterials(accessToken: String) async throws -> FB_UD_MPC.SetupTokenResponse {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func waitForTransactionWithNewKeyMaterialsReady(accessToken: String) async throws {
        try failIfNeeded()
    }
    
    func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws -> FB_UD_MPC.AuthTokens {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func verifyAccessToken(_ accessToken: String) async throws {
        try failIfNeeded()
    }
    
    var refreshTokenCalls = [String]()
    func refreshToken(_ refreshToken: String) async throws -> FB_UD_MPC.AuthTokens {
        queue.sync {
            refreshTokenCalls.append(refreshToken)
        }
        await Task.sleep(seconds: 0.2)
        try failIfNeeded()
        return MPCEntitiesBuilder.createAuthTokens()
    }
    
    var refreshBootstrapCalls = [String]()
    func refreshBootstrapToken(_ bootstrapToken: String) async throws -> FB_UD_MPC.RefreshBootstrapTokenResponse {
        queue.sync {
            refreshBootstrapCalls.append(bootstrapToken)
        }
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    var getAccountsCalls = [String]()
    func getAccounts(accessToken: String) async throws -> FB_UD_MPC.WalletAccountsResponse {
        queue.sync {
            getAccountsCalls.append(accessToken)
        }
        await Task.sleep(seconds: 0.2)
        try failIfNeeded()
        return .init(items: [.init(type: "", id: "")], next: nil)
    }
    
    func getAccountAssets(accountId: String, accessToken: String, includeBalances: Bool) async throws -> FB_UD_MPC.WalletAccountAssetsResponse {
        await Task.sleep(seconds: 0.2)
        try failIfNeeded()
        return .init(items: [MPCEntitiesBuilder.createAccountAsset()], next: nil)
    }
    
    func getSupportedBlockchainAssets(accessToken: String) async throws -> FB_UD_MPC.SupportedBlockchainAssetsResponse {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func startMessageSigning(accessToken: String, accountId: String, assetId: String, message: String, encoding: FB_UD_MPC.SignMessageEncoding) async throws -> FB_UD_MPC.OperationDetails {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func startAssetTransfer(accessToken: String, accountId: String, assetId: String, destinationAddress: String, amount: String) async throws -> FB_UD_MPC.OperationDetails {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func waitForOperationReadyAndGetTxId(accessToken: String, operationId: String) async throws -> FB_UD_MPC.OperationReadyResponse {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func waitForOperationSignedAndGetTxSignature(accessToken: String, operationId: String) async throws -> String {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func waitForOperationCompleted(accessToken: String, operationId: String) async throws {
        try failIfNeeded()
    }
    
    func waitForTxCompletedAndGetHash(accessToken: String, operationId: String) async throws -> String {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func fetchCryptoPortfolioForMPC(wallet: String, accessToken: String) async throws -> [WalletTokenPortfolio] {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
    
    func getAssetTransferEstimations(accessToken: String, accountId: String, assetId: String, destinationAddress: String, amount: String) async throws -> FB_UD_MPC.NetworkFeeResponse {
        try failIfNeeded()
        throw TestableGenericError.generic
    }
}

private final class MockMPCWalletsDataStorage: FB_UD_MPC.MPCWalletsDataStorage {
    var authTokens: [String : FB_UD_MPC.AuthTokens] = [:]
    var accountDetails: [String : FB_UD_MPC.ConnectedWalletAccountsDetails] = [:]
    
    func storeAuthTokens(_ tokens: FB_UD_MPC.AuthTokens, for deviceId: String) throws {
        authTokens[deviceId] = tokens
    }
    
    func clearAuthTokensFor(deviceId: String) throws {
        authTokens[deviceId] = nil
    }
    
    func retrieveAuthTokensFor(deviceId: String) throws -> FB_UD_MPC.AuthTokens {
        guard let tokens = authTokens[deviceId] else { throw MockMPCWalletsDataStorageError.noTokens }
        
        return tokens
    }
    
    func storeAccountsDetails(_ accountsDetails: FB_UD_MPC.ConnectedWalletAccountsDetails) throws {
        accountDetails[accountsDetails.deviceId] = accountsDetails
    }
    
    func clearAccountsDetailsFor(deviceId: String) throws {
        accountDetails[deviceId] = nil
    }
    
    func retrieveAccountsDetailsFor(deviceId: String) throws -> FB_UD_MPC.ConnectedWalletAccountsDetails {
        guard let tokens = accountDetails[deviceId] else { throw MockMPCWalletsDataStorageError.noAccountDetails }
        
        return tokens
    }
    
    enum MockMPCWalletsDataStorageError: String, LocalizedError {
        case noTokens
        case noAccountDetails
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

private final class MockMPCWalletUIHandler: MPCWalletsUIHandler {
    func askToReconnectMPCWallet(_ reconnectData: MPCWalletReconnectData) async {
        
    }
}
