//
//  MPCNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import Foundation

final class MPCNetworkService {
    
    private let networkService = NetworkService()
    
    static let shared = MPCNetworkService()
    
    private init() { }
    
    enum URLSList {
        static var baseURL: String {
            "https://api-ud.staging.com"
        }
        
        static var v1URL: String { baseURL.appendingURLPathComponents("wallet", "v1") }
        
        static var tempGetCodeURL: String { v1URL.appendingURLPathComponents("admin", "auth", "bootstrap-code") }
        static var submitCodeURL: String { v1URL.appendingURLPathComponents("auth", "bootstrap") }
        static var rpcMessagesURL: String { v1URL.appendingURLPathComponents("rpc", "messages") }
        static var devicesBootstrapURL: String { v1URL.appendingURLPathComponents("devices", "bootstrap") }
        
        static var tokensURL: String { v1URL.appendingURLPathComponents("tokens") }
        static var tokensSetupURL: String { tokensURL.appendingURLPathComponents("setup") }
        static var tokensConfirmURL: String { tokensURL.appendingURLPathComponents("confirm") }
        static var tokensVerifyURL: String { tokensURL.appendingURLPathComponents("verify") }
        
        
    }
    
}

// MARK: - Open methods
extension MPCNetworkService {
    /// Currently it will use admin route to generate code and log intro console.
    func sendBootstrapCodeTo(email: String) async throws {
        
        struct Body: Encodable {
            let walletExternalId: String // wa-wt-<wallet id>
            
            init(walletId: String) {
                self.walletExternalId = "wa-wt-\(walletId)"
            }
        }
        
        // TBD
        struct Response: Decodable {
            let code: String
        }
        
        let body = Body(walletId: "123")
        let request = try APIRequest(urlString: URLSList.tempGetCodeURL,
                                     body: body,
                                     method: .post)
        
        let response: Response = try await NetworkService().makeDecodableAPIRequest(request)
        
        print("Did receive MPC bootstrap code: \(response.code)")
    }
    
    func submitBootstrapCode(_ code: String) async throws {
        struct Body: Encodable {
            let code: String
            var device: String? = nil
        }
        
        struct Response: Decodable {
//            let type: String
            let accessToken: String // temp access token
            let deviceId: String
        }
        
        let body = Body(code: code)
        let request = try APIRequest(urlString: URLSList.submitCodeURL,
                                     body: body,
                                     method: .post)
        
        let response: Response = try await NetworkService().makeDecodableAPIRequest(request)
        
        //    // Returns a temp access token and the deviceId
        //
        //    // Initialize the Fireblocks NCW SDK
        //    const fbOptions: IFireblocksNCWOptions = {
        //        deviceId,
        //    messagesHandler: messageProvider,
        //    eventsHandler: eventsHandler,
        //    secureStorageProvider: secureKeyStorageProvider,
        //    storageProvider: unsecureStorageProvider,
        //    logger: sdkLogger,
        //    };
        //
        //    return await FireblocksNCWFactory(fbOptions);
    }
    
    func messagesHandler(message: Data, accessToken: String) async throws {
        
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: URLSList.rpcMessagesURL,
                                     body: message,
                                     method: .post,
                                     headers: headers)
        
    }
    
    func requestJoinExistingWalletHandler(walletJoinRequestId: String,
                                          recoveryPhrase: String,
                                          accessToken: String) async throws {
        // Get walletJoinRequestId from the SDK
//        const joinResult = await sdk.requestJoinExistingWallet({
//        onRequestId: async (requestId) => {
//            // call Wallets API
//        },
//        onProvisionerFound: () => {
//            this.logger.log('Provisioner found');
//        },
//        });
        
        struct Body: Encodable {
            let walletJoinRequestId: String
            var recoveryPhrase: String
        }
        
        let body = Body(walletJoinRequestId: walletJoinRequestId, recoveryPhrase: recoveryPhrase)
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: URLSList.devicesBootstrapURL,
                                     body: body,
                                     method: .post,
                                     headers: headers)
        
        try await waitForKeyIsReady()
    }
    
    
    func waitForKeyIsReady() async throws {
        
        //    // Poll until the key is ready
        //    private async waitForKeyReady(
        //        sdk: IFireblocksNCW,
        //        maxAttempts: number = 50,
        //    ): Promise<void> {
        //        for (let i = 1; i <= maxAttempts; i++) {
        //            const status = await sdk.getKeysStatus();
        //            if (status.MPC_CMP_ECDSA_SECP256K1.keyStatus === 'READY') {
        //                break;
        //            }
        //            await sleep(500);
        //        }
        //    }
    }
    
    
    
    // Once we have the key material, now it’s time to get a full access token to the Wallets API. To prove that the key material is valid, you need to create a transaction to sign
    // Initialize a transaction with the Wallets API
    func initTransactionWithNewKeyMaterials(accessToken: String) async throws {
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: URLSList.tokensSetupURL,
                                     method: .post,
                                     headers: headers)
        
        // SetupTokenResponse
    }
    
//    We have to wait for Fireblocks to also sign, so poll the Wallets API until the transaction is returned with the PENDING_SIGNATURE status
    func checkTransactionWithNewKeyMaterialsStatus(accessToken: String) async throws {
        
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: URLSList.tokensSetupURL,
                                     method: .get,
                                     headers: headers)
//        SetupTokenResponse
    }
    
//    Once it is pending a signature, sign with the Fireblocks NCW SDK and confirm with the Wallets API that you have signed. After confirmation is validated, you’ll be returned an access token, a refresh token and a bootstrap token.
    func confirmTransactionWithNewKeyMaterialsSigned(accessToken: String) async throws {
        
        struct Body: Encodable {
            var includeRefreshToken: Bool = true
            var includeBootstrapToken: Bool = true
        }
        
        struct Response: Decodable {
            let accessToken: String
            let refreshToken: String
            let bootstrapToken: String
        }
        
        
        let body = Body()
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: URLSList.tokensConfirmURL,
                                     body: body,
                                     method: .post,
                                     headers: headers)
    }
    
    
    func verifyAccessToken(_ accessToken: String) async throws {
        let headers = buildAuthBearerHeader(token: accessToken)
        let request = try APIRequest(urlString: URLSList.tokensVerifyURL,
                                     method: .get,
                                     headers: headers)
    }
}

// MARK: - Private methods
private extension MPCNetworkService {
    func buildAuthBearerHeader(token: String) -> [String : String] {
        ["Authorization":"Bearer \(token)"]
    }
    
    struct SetupTokenResponse: Decodable {
        let transactionId: String // temp access token
        let  status: String // 'QUEUED' | 'PENDING_SIGNATURE' | 'COMPLETED' | 'UNKNOWN';
    }
    
}
