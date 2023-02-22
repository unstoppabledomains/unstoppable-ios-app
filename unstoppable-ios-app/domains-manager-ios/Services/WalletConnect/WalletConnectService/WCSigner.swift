//
//  WCSigner.swift
//  domains-manager-ios
//
//  Created by Roman on 02.07.2022.
//

import Foundation
import WalletConnectSwift
import Web3
import PromiseKit

typealias WCConnectionResult = Swift.Result<PushSubscriberInfo?, Swift.Error>
typealias WCConnectionResultCompletion = ((WCConnectionResult)->())

protocol WalletConnectV1RequestHandlingServiceProtocol {
    func registerRequestHandler(_ requestHandler: RequestHandler)
    func connectAsync(to requestURL: WCURL, completion: @escaping WCConnectionResultCompletion)
    func sendResponse(_ response: Response)
    
    func handlePersonalSign(request: Request) async throws -> Response
    func handleSignTx(request: Request) async throws -> Response
    func handleGetTransactionCount(request: Request) async throws -> Response
    func handleEthSign(request: Request) async throws -> Response
    func handleSendTx(request: Request) async throws -> Response
    func handleSendRawTx(request: Request) async throws -> Response
    func handleSignTypedData(request: Request) async throws -> Response
}

extension WalletConnectV1RequestHandlingServiceProtocol {
    func detectConnectedApp(by walletAddress: HexAddress, request: Request) throws -> (WCConnectedAppsStorage.ConnectedApp, UDWallet) {
        guard let connectedApp = WCConnectedAppsStorage.shared.find(by: [walletAddress], topic: request.url.topic)?.first,
              let udWallet = appContext.udWalletsService.find(by: walletAddress) else {
            Debugger.printFailure("No connected app can sign for the wallet address \(walletAddress) from request \(request)", critical: true)
            throw WalletConnectService.Error.failedToFindWalletToSign
        }
        return (connectedApp, udWallet)
    }
}

extension WalletConnectService: WalletConnectV1RequestHandlingServiceProtocol {
    func registerRequestHandler(_ requestHandler: WalletConnectSwift.RequestHandler) {
        server.register(handler: requestHandler)
    }
    
    func sendResponse(_ response: WalletConnectSwift.Response) {
        server.send(response)
    }
    
    enum Error: String, Swift.Error, RawValueLocalizable {
        case failedConnectionRequest
        case failedToFindWalletToSign
        case failedToGetPrivateKey
        case failedToSignMessage
        case failedToSignTransaction
        case failedToDetermineChainId
        case failedToDetermineIntent
        case failedToParseMessage
        case uiHandlerNotSet
        case networkNotSupported
        case noWCSessionFound
        case externalWalletFailedToSend
        case externalWalletFailedToSign
        case failedParseResultFromExtWallet
        case failedCreateTxForExtWallet
        case invalidWCRequest
        case appAlreadyConnected
        case failedFetchNonce
        case failedFetchGas
        case failedFetchGasPrice
        case lowAllowance
        case failedToBuildCompleteTransaction
        case connectionTimeout
        case invalidNamespaces
        case failedParseSendTxResponse
        case failedSendTx
        case methodUnsupported
        case failedBuildParams
        
        var groupType: ErrorGroup {
            switch self {
            case .failedToFindWalletToSign,
                    .uiHandlerNotSet,
                    .failedConnectionRequest,
                    .failedToGetPrivateKey,
                    .appAlreadyConnected,
                    .failedToDetermineIntent,
                    .invalidNamespaces: return .failedConnection
            case .failedToSignMessage,
                    .failedToDetermineChainId,
                    .noWCSessionFound,
                    .externalWalletFailedToSend,
                    .externalWalletFailedToSign,
                    .failedParseResultFromExtWallet,
                    .failedCreateTxForExtWallet,
                    .invalidWCRequest,
                    .failedToParseMessage,
                    .failedFetchNonce,
                    .failedFetchGas,
                    .failedFetchGasPrice,
                    .failedToBuildCompleteTransaction,
                    .failedParseSendTxResponse,
                    .failedSendTx,
                    .failedToSignTransaction,
                    .failedBuildParams: return .failedTx
            case .methodUnsupported: return .methodUnsupported
            case .networkNotSupported: return .networkNotSupported
            case .lowAllowance: return .lowAllowance
            case .connectionTimeout: return .connectionTimeout
            }
        }
    }
    
    enum ErrorGroup {
        case failedConnection
        case failedTx
        case networkNotSupported
        case lowAllowance
        case connectionTimeout
        case methodUnsupported
    }
    
    var walletConnectClientService: WalletConnectClientServiceProtocol { appContext.walletConnectClientService }
        
    func handlePersonalSign(request: Request) async throws -> Response {
        
        let messageString = try request.parameter(of: String.self, at: 0)
        let address = try request.parameter(of: String.self, at: 1)
        Debugger.printInfo(topic: .WallectConnect, "Incoming request with payload: \(request.jsonString)")
        
        let (_, udWallet) = try await getWalletAfterConfirmationIfNeeded(address: address,
                                                                         request: request,
                                                                         messageString: messageString)
        let sig: String
        do {
            sig = try await udWallet.getCryptoSignature(messageString: messageString)
        } catch {
            //TODO: If the error == WalletConnectError.failedOpenExternalApp
            // the mobile wallet app may have been deleted
            
            Debugger.printFailure("Failed to sign message: \(messageString) by wallet:\(address)", critical: true)
            throw error
        }
        return Response.signature(sig, for: request)
//            self.server.send()
//            notifyDidHandleExternalWCRequestWith(result: .success(()))
//        } catch {
//            Debugger.printFailure("Signing a message was interrupted: \(error.localizedDescription)")
//            server.send(.invalid(request))
//            notifyDidHandleExternalWCRequestWith(result: .failure(error))
//        }
    }
    
    struct TxDisplayDetails {
        let quantity: BigUInt
        let gasPrice: BigUInt
        let gasLimit: BigUInt
        let description: String
        
        var gasFee: BigUInt {
            gasPrice * gasLimit
        }
        
        init?(tx: EthereumTransaction) {
            guard let quantity = tx.value?.quantity,
                  let gasPrice = tx.gasPrice?.quantity,
                  let gasLimit = tx.gas?.quantity else { return nil }
            
            
            self.quantity = quantity
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
            self.description = tx.description
        }
    }
    
    func handleSignTx(request: WalletConnectSwift.Request) async throws -> Response {
        let transaction = try request.parameter(of: EthereumTransaction.self, at: 0)
        guard let address = transaction.from?.hex(eip55: true).normalized else {
            throw Error.failedToFindWalletToSign
        }
        
        let (connectedApp, udWallet) = try await getWalletAfterConfirmationIfNeeded(address: address,
                                                                                    request: request,
                                                                                    transaction: transaction)
        
        guard udWallet.walletState != .externalLinked else {
            guard let sessionWithExtWallet = walletConnectClientService.findSessions(by: address).first else {
                Debugger.printFailure("Failed to find session for WC", critical: false)
                throw Error.noWCSessionFound
            }
            
//            udWallet.signTxViaWalletConnect(session: sessionWithExtWallet, tx: transaction)
//                .done { response in
//                    if let error = response.error {
//                        Debugger.printFailure("Error from the signing ext wallet: \(error)", critical: true)
//                        self.server.send(.invalid(request))
//                        return
//                    }
//                    do {
//                        let result = try response.result(as: String.self)
//                        self.server.send(Response.signature(result, for: request))
//                        self.notifyDidHandleExternalWCRequestWith(result: .success(()))
//                    } catch {
//                        Debugger.printFailure("Error parsing result from the signing ext wallet: \(error)", critical: true)
//                        self.server.send(.invalid(request))
//                        self.notifyDidHandleExternalWCRequestWith(result: .failure(error))
//                    }
//                }.catch { error in
//                    Debugger.printFailure("Failed to send a request to the signing ext wallet: \(error)", critical: true)
//                    self.server.send(.invalid(request))
//                    self.notifyDidHandleExternalWCRequestWith(result: .failure(error))
//                }
            
            // TODO: - WC test when fixed.
            let response = try await udWallet.signTxViaWalletConnect(session: sessionWithExtWallet, tx: transaction)
            if let error = response.error {
                Debugger.printFailure("Error from the signing ext wallet: \(error)", critical: true)
                throw error
            }
            let result = try response.result(as: String.self)
            return Response.signature(result, for: request)
        }
        
        guard let privKeyString = udWallet.getPrivateKey() else {
            Debugger.printFailure("No private key in \(udWallet)", critical: true)
            throw Error.failedToGetPrivateKey
        }
        
        let privateKey = try EthereumPrivateKey(hexPrivateKey: privKeyString)
        
        let chainId = EthereumQuantity(quantity: BigUInt(connectedApp.session.dAppInfo.getChainId()))
        let signedTx = try transaction.sign(with: privateKey, chainId: chainId)
        let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
        let signature = r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)
        return Response.signature(signature, for: request)
    }
    
    func handleEthSign(request: Request) async throws -> Response {
        throw Error.methodUnsupported
    }
        
    func handleSendTx(request: WalletConnectSwift.Request) async throws -> Response {
        let _transaction = try request.parameter(of: EthereumTransaction.self, at: 0)
        
        guard let walletAddress = _transaction.from?.hex(eip55: true) else {
            throw Error.failedToFindWalletToSign
        }
        
        let (connectedApp, udWallet) = try detectConnectedApp(by: walletAddress, request: request)
        guard let chainIdInt = connectedApp.session.walletInfo?.chainId else {
            Debugger.printFailure("Failed to find chainId for request: \(request)", critical: true)
            throw Error.failedToDetermineChainId
        }
        
        let completedTx = try await completeTx(transaction: _transaction,  chainId: chainIdInt)
        
        let (_, _) = try await getWalletAfterConfirmationIfNeeded(address: walletAddress,
                                                                  request: request,
                                                                  transaction: completedTx)
        guard udWallet.walletState != .externalLinked else {
            guard let sessionWithExtWallet = walletConnectClientService.findSessions(by: walletAddress).first else {
                Debugger.printFailure("Failed to find session for WC", critical: false)
                throw Error.noWCSessionFound
            }
            
            let response = try await proceedSendTxViaWC(by: udWallet, during: sessionWithExtWallet, in: request, transaction: completedTx)
            Debugger.printInfo(topic: .WallectConnect, "Successfully sent TX via external wallet: \(udWallet.address)")
            return response
        }
        
        return try await sendTx(transaction: completedTx,
                                request: request,
                                udWallet: udWallet,
                                chainIdInt: chainIdInt)
    }
    
    func completeTx(transaction: EthereumTransaction,
                            chainId: Int) async throws -> EthereumTransaction {
        var txBuilding = transaction
        
        if txBuilding.gasPrice == nil {
            guard let gasPrice = await fetchGasPrice(chainId: chainId) else {
                throw WalletConnectService.Error.failedFetchGas
            }
            txBuilding.gasPrice = EthereumQuantity(quantity: gasPrice)
        }
                
        txBuilding = try await ensureGasLimit(transaction: txBuilding, chainId: chainId)
        txBuilding = try await ensureNonce(transaction: txBuilding, chainId: chainId)
        
        if txBuilding.value == nil {
            txBuilding.value = 0
        }
        return txBuilding
    }
    
    func sendTx(transaction: EthereumTransaction,
                request: Request,
                udWallet: UDWallet,
                chainIdInt: Int) async throws -> Response {
        
        guard let urlString = NetworkService().getJRPCProviderUrl(chainId: chainIdInt)?.absoluteString else {
            Debugger.printFailure("Failed to get net name for chain Id: \(chainIdInt)", critical: true)
            throw WalletConnectService.Error.failedToDetermineChainId
        }
        let web3 = Web3(rpcURL: urlString)
        guard let privKeyString = udWallet.getPrivateKey() else {
            Debugger.printFailure("No private key in \(udWallet)", critical: true)
            throw Error.failedToGetPrivateKey
        }
        let privateKey = try EthereumPrivateKey(hexPrivateKey: privKeyString)
        let chainId = EthereumQuantity(quantity: BigUInt(chainIdInt))
        
        let gweiAmount = (transaction.gas ?? 0).quantity * (transaction.gasPrice ?? 0).quantity + (transaction.value ?? 0).quantity
        Debugger.printInfo(topic: .WallectConnect, "Total balance should be \(gweiAmount / ( BigUInt(10).power(12)) ) millionth of eth")
        let signedTransaction = try transaction.sign(with: privateKey, chainId: chainId)
        return try await withSafeCheckedThrowingContinuation({ completion in
            signedTransaction.promise
                .then { tx in
                    web3.eth.sendRawTransaction(transaction: tx) }
                .done { hash in
                    guard let result = hash.ethereumValue().string else {
                        Debugger.printFailure("Failed to parse response from sending: \(transaction)")
                        completion(.failure(Error.failedParseSendTxResponse))
                        return
                    }
                    let response = Response.transaction(result, for: request)
                    completion(.success(response))
                }.catch { error in
                    Debugger.printFailure("Sending a TX was failed: \(error.localizedDescription)")
                    completion(.failure(Error.failedSendTx))
                }
        })
    }
    
    func handleSendRawTx(request: WalletConnectSwift.Request) async throws -> Response {
        // TODO: check if this is correct way of initialising Raw TX
        let tx = try? EthereumSignedTransaction(rlp: RLPItem(bytes: Data().bytes))
        
        Debugger.printFailure("Unsupported method: \(request.method)")
        throw Error.methodUnsupported
    }
    
    func handleSignTypedData(request: WalletConnectSwift.Request) async throws -> Response {
        let walletAddress = try request.parameter(of: String.self, at: 0)
        let dataString = try request.parameter(of: String.self, at: 1)
        
        Debugger.printInfo(topic: .WallectConnect, "Incoming request with payload: \(request.jsonString)")
        // TODO: - Roman. For not external wallet, it will ask confirmation and then fail.
        let (_, udWallet) = try await self.getWalletAfterConfirmationIfNeeded(address: walletAddress,
                                                                              request: request,
                                                                              messageString: dataString)
        
        guard udWallet.walletState != .externalLinked else {
            guard let sessionWithExtWallet = walletConnectClientService.findSessions(by: walletAddress).first else {
                Debugger.printFailure("Failed to find session for WC", critical: false)
                throw Error.noWCSessionFound
            }
            
            let response = try await proceedSignTypedDataViaWC(by: udWallet, during: sessionWithExtWallet, in: request, dataString: dataString)
            return response
        }
        
        throw Error.methodUnsupported
        
        /*
         guard let data = dataString.data(using: .utf8) else { throw ResponseError.invalidRequest }
         let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: data)
         guard let signature = try udWallet.signHashedMessage(typedData.signHash) else {
         Debugger.printFailure("Failed to sign the digest of typed data", critical: true)
         self.server.send(.invalid(request))
         return
         }
         self.server.send(Response.signature("0x" + signature.dataToHexString(), for: request))
         */
    }
    
    func handleGetTransactionCount(request: Request) async throws -> Response {
        let walletAddress = try request.parameter(of: HexAddress.self, at: 0)
        guard let app = WCConnectedAppsStorage.shared.find(by: walletAddress),
              let chainId = app.session.walletInfo?.chainId else {
            Debugger.printFailure("Failed to find chainId for request: \(request)", critical: true)
            throw Error.failedToDetermineChainId
        }
        guard let nonce = await fetchNonce(address: walletAddress, chainId: chainId) else {
            throw Error.failedFetchNonce
        }
        return Response.nonce(nonce, for: request)
    }
    
    private func getWalletAfterConfirmationIfNeeded(address: HexAddress,
                                            request: Request,
                                            transaction: EthereumTransaction) async throws -> (WCConnectedAppsStorage.ConnectedApp, UDWallet) {
        guard let cost = TxDisplayDetails(tx: transaction) else { throw Error.failedToBuildCompleteTransaction }
        return try await getWalletAfterConfirmation_generic(address: address, request: request) {
            WCRequestUIConfiguration.payment(SignPaymentTransactionUIConfiguration(connectionConfig: $0,
                                                                                   walletAddress: address,
                                                                                   cost: cost))
        }
    }
    
    private func getWalletAfterConfirmationIfNeeded(address: HexAddress,
                                            request: Request,
                                            messageString: String) async throws -> (WCConnectedAppsStorage.ConnectedApp, UDWallet) {
        try await getWalletAfterConfirmation_generic(address: address, request: request) {
            WCRequestUIConfiguration.signMessage(SignMessageTransactionUIConfiguration(connectionConfig: $0,
                                                                                       signingMessage: messageString))
        }
    }
    
    private func getWalletAfterConfirmation_generic(address: HexAddress,
                                             request: Request,
                                             uiConfigBuilder: (ConnectionConfig)-> WCRequestUIConfiguration ) async throws -> (WCConnectedAppsStorage.ConnectedApp, UDWallet) {
        let (connectedApp, udWallet) = try detectConnectedApp(by: address, request: request)
        
        if udWallet.walletState != .externalLinked {
            guard let uiHandler = self.uiHandler else {
                Debugger.printFailure("UI Handler is not set", critical: true)
                throw Error.uiHandlerNotSet
            }

            let connectionConfig = ConnectionConfig(domain: connectedApp.domain,
                                                    appInfo: Self.appInfo(from: connectedApp.session))
            let uiConfig = uiConfigBuilder(connectionConfig)
            try await uiHandler.getConfirmationToConnectServer(config: uiConfig)
        }
        return (connectedApp, udWallet)
    }
    
    private func proceedSendTxViaWC(by udWallet: UDWallet,
                                    during session: Session,
                                    in request: Request,
                                    transaction: EthereumTransaction) async throws -> Response {
        try await withSafeCheckedThrowingContinuation({ completion in
            proceedSendTxViaWC(by: udWallet, during: session, in: request, transaction: transaction)
                .done { (result: Response) in
                    completion(.success(result))
                }.catch { error in
                    completion(.failure(error))
                }
        })
    }
    
    private func proceedSendTxViaWC(by udWallet: UDWallet,
                                    during session: Session,
                                    in request: Request,
                                    transaction: EthereumTransaction) -> Promise<Response> {
        let promise = udWallet.sendTxViaWalletConnect(session: session, tx: transaction)
        Task { try? await udWallet.launchExternalWallet() }
        return commonProceedHandleTxViaWC(requestPromise: promise, in: request)
    }
    
    private func proceedSignTypedDataViaWC(by udWallet: UDWallet,
                                           during session: Session,
                                           in request: Request,
                                           dataString: String) async throws -> Response {
        try await withSafeCheckedThrowingContinuation({ completion in
            proceedSignTypedDataViaWC(by: udWallet, during: session, in: request, dataString: dataString)
                .done { (result: Response) in
                    completion(.success(result))
                }.catch { error in
                    completion(.failure(error))
                }
        })
    }
    
    private func proceedSignTypedDataViaWC(by udWallet: UDWallet,
                                           during session: Session,
                                           in request: Request,
                                           dataString: String) -> Promise<Response> {
        let promise = udWallet.signTypedDataViaWalletConnect(session: session,
                                                             walletAddress: udWallet.address,
                                                             message: dataString)
        Task { try? await udWallet.launchExternalWallet() }
        return commonProceedHandleTxViaWC(requestPromise: promise, in: request)
    }
    
    private func commonProceedHandleTxViaWC(requestPromise: Promise<Response>,
                                            in request: Request) -> Promise<Response> {
        requestPromise.then { (response: Response) -> Promise<Response> in
            if let error = response.error {
                Debugger.printFailure("Error from the sending ext wallet: \(error)", critical: true)
                return Promise() { $0.reject(WalletConnectService.Error.externalWalletFailedToSend) }
            }
            do {
                let result = try response.result(as: String.self)
                return Promise() { $0.fulfill(Response.transaction(result, for: request)) }
            } catch {
                Debugger.printFailure("Error parsing result from the sending ext wallet: \(error)", critical: true)
                return Promise() { $0.reject(WalletConnectService.Error.failedParseResultFromExtWallet) }
            }
        }
    }
}

extension WalletConnectService {
    private func fetchNonce(transaction: EthereumTransaction, chainId: Int) async -> String? {
        guard let addressString = transaction.from?.hex() else { return nil }
        return await fetchNonce(address: addressString, chainId: chainId)
    }
    
    private func fetchNonce(address: HexAddress, chainId: Int) async -> String? {
        await withSafeCheckedContinuation { completion in
            NetworkService().getTransactionCount(address: address,
                                                 chainId: chainId) { response in
                guard let nonceString = response else {
                    Debugger.printFailure("Failed to fetch nonce for address: \(address)", critical: true)
                    completion(nil)
                    return
                }
                Debugger.printInfo(topic: .WallectConnect, "Fetched nonce successfully: \(nonceString)")
                completion(nonceString)
            }
        }
    }
    
    private func ensureNonce(transaction: EthereumTransaction, chainId: Int) async throws -> EthereumTransaction {
        guard transaction.nonce == nil else {
            return transaction
        }
        
        guard let nonce = await fetchNonce(transaction: transaction, chainId: chainId),
              let nonceBig = BigUInt(nonce.droppedHexPrefix, radix: 16) else {
            throw WalletConnectService.Error.failedFetchNonce
        }
        var newTx = transaction
        newTx.nonce = EthereumQuantity(quantity: nonceBig)
        return newTx
    }
    
    private func fetchGasLimit(transaction: EthereumTransaction, chainId: Int) async throws -> BigUInt {
        try await withSafeCheckedThrowingContinuation { completion in
            NetworkService().getGasEstimation(tx: transaction,
                                                 chainId: chainId) { response in
                
                switch response {
                case .fulfilled(let gasPriceString):
                    guard let result = BigUInt(gasPriceString.droppedHexPrefix, radix: 16) else {
                        Debugger.printFailure("Failed to parse gas Estimate from: \(gasPriceString)", critical: true)
                        completion(.failure(WalletConnectService.Error.failedFetchGas))
                        return
                    }
                    Debugger.printInfo(topic: .WallectConnect, "Fetched gas Estimate successfully: \(gasPriceString)")
                    completion(.success(result))
                case .rejected(let error):
                    if let jrpcError = error as? NetworkService.JRPCError {
                        switch jrpcError {
                        case .gasRequiredExceedsAllowance:
                            Debugger.printFailure("Failed to fetch gas Estimate because of Low Allowance Error", critical: false)
                            completion(.failure(WalletConnectService.Error.lowAllowance))
                            return
                        default: break
                        }
                    }
                    
                    Debugger.printFailure("Failed to fetch gas Estimate: \(error.localizedDescription)", critical: false)
                    completion(.failure(WalletConnectService.Error.failedFetchGas))
                    return
                }
            }
        }
    }
    
    private func ensureGasLimit(transaction: EthereumTransaction, chainId: Int) async throws -> EthereumTransaction {
        guard transaction.gas == nil else {
            return transaction
        }
        
        let gas = try await fetchGasLimit(transaction: transaction, chainId: chainId)
        var newTx = transaction
        newTx.gas = EthereumQuantity(quantity: gas)
        return newTx
    }
    
    private func fetchGasPrice(chainId: Int) async -> BigUInt? {
        await withSafeCheckedContinuation { completion in
            NetworkService().getGasPrice(chainId: chainId) { response in
                guard let gasPrice = response else {
                    Debugger.printFailure("Failed to fetch gasPrice", critical: false)
                    completion(nil)
                    return
                }
                Debugger.printInfo(topic: .WallectConnect, "Fetched gasPrice successfully: \(gasPrice)")
                completion(BigUInt(gasPrice.droppedHexPrefix, radix: 16))
            }
        }
    }
}

extension EthereumTransaction {
    var description: String {
        return """
        to: \(to == nil ? "" : String(describing: to!.hex(eip55: true))),
        value: \(value == nil ? "" : String(describing: value!.hex())),
        gasPrice: \(gasPrice == nil ? "" : String(describing: gasPrice!.hex())),
        gas: \(gas == nil ? "" : String(describing: gas!.hex())),
        data: \(data.hex()),
        nonce: \(nonce == nil ? "" : String(describing: nonce!.hex()))
        """
    }
}

extension UDWallet {
    func signTxViaWalletConnect(session: Session, tx: EthereumTransaction) async throws -> Response {
        try await withSafeCheckedThrowingContinuation { completion in
            signTxViaWalletConnect(session: session, tx: tx)
                .done { response in
                    completion(.success(response))
                }.catch { error in
                    Debugger.printFailure("Failed to send a request to the signing ext wallet: \(error)", critical: true)
                    completion(.failure(error))
                }
        }
    }
    
    func signTxViaWalletConnect(session: Session, tx: EthereumTransaction) -> Promise<Response> {
        return Promise { seal in
            guard let transaction = Client.Transaction(ethTx: tx) else {
                seal.reject(WalletConnectService.Error.failedCreateTxForExtWallet)
                return
            }
            
            let client = appContext.walletConnectClientService.getClient()

            do {
                try client.eth_signTransaction(url: session.url, transaction: transaction) { response in
                    seal.fulfill(response)
                }
            } catch {
                seal.reject(WalletConnectError.failedToRelayTxToExternalWallet)
            }
        }
    }
    
    func sendTxViaWalletConnect(session: Session,
                                tx: EthereumTransaction) -> Promise<Response> {
        return Promise { seal in
            guard let transaction = Client.Transaction(ethTx: tx) else {
                seal.reject(WalletConnectService.Error.failedCreateTxForExtWallet)
                return
            }
            let client = appContext.walletConnectClientService.getClient()
            do {
                try client.eth_sendTransaction(url: session.url, transaction: transaction) { response in
                    seal.fulfill(response)
                }
            } catch {
                seal.reject(WalletConnectError.failedToRelayTxToExternalWallet)
            }
        }
    }
    
    func signTxViaWalletConnectV1Async(session: Session,
                                     tx: EthereumTransaction,
                                     requestSentCallback: ()->Void) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            guard let transaction = Client.Transaction(ethTx: tx) else {
                return continuation.resume(with: .failure(WalletConnectService.Error.failedCreateTxForExtWallet))
            }
            
            let client = appContext.walletConnectClientService.getClient()
            
            do {
                try client.eth_signTransaction(url: session.url, transaction: transaction) { response in
                    return continuation.resume(with: .success(response))
                }
                requestSentCallback()
            } catch {
                return continuation.resume(with: .failure(WalletConnectError.failedToRelayTxToExternalWallet))
            }
        }
    }
    
    func sendTxViaWalletConnectAsync(session: Session,
                                     tx: EthereumTransaction,
                                     requestSentCallback: ()->Void ) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            guard let transaction = Client.Transaction(ethTx: tx) else {
                return continuation.resume(with: .failure(WalletConnectService.Error.failedCreateTxForExtWallet))
            }
            let client = appContext.walletConnectClientService.getClient()
            do {
                try client.eth_sendTransaction(url: session.url, transaction: transaction) { response in
                    return continuation.resume(with: .success(response))
                }
                requestSentCallback()
            } catch {
                return continuation.resume(with: .failure(WalletConnectError.failedToRelayTxToExternalWallet))
            }
        }
    }
    
    func signTypedDataViaWalletConnect(session: Session, walletAddress: HexAddress, message: String) -> Promise<Response> {
        return Promise { seal in
            let client = appContext.walletConnectClientService.getClient()
            do {
                try client.eth_signTypedData(url: session.url, account: walletAddress, message: message) { response in
                    seal.fulfill(response)
                }
            } catch {
                seal.reject(WalletConnectError.failedToRelayTxToExternalWallet)
            }
        }
    }
}

extension Client.Transaction {
    init?(ethTx: EthereumTransaction) {
        guard let fromAddress = ethTx.from else {
            return nil
        }
        
        let from = fromAddress.hex()
        let to = ethTx.to.map({$0.hex()})
        let data = ethTx.data.hex()
        let gas = ethTx.gas.map({$0.hex()})
        let gasPrice = ethTx.gasPrice.map({$0.hex()})
        let value = ethTx.value.map({$0.hex()})
        let nonce = ethTx.nonce.map({$0.hex()})
        
        self.init(from: from, to: to, data: data, gas: gas, gasPrice: gasPrice, value: value, nonce: nonce, type: nil, accessList: nil, chainId: nil, maxPriorityFeePerGas: nil, maxFeePerGas: nil)
    }
}
