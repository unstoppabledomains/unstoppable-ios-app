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

protocol WCSigner: AnyObject {
    func handlePersonalSign(request: Request)
    func handleSignTx(request: Request)
    
    func handleGetTransactionCount(request: Request)
    
    func handleEthSign(request: Request)
    func handleSendTx(request: Request)
    func handleSendRawTx(request: Request)
    func handleSignTypedData(request: Request)
}

extension WCSigner {
    func detectConnectedApp(by walletAddress: HexAddress, request: Request) throws -> (WCConnectedAppsStorage.ConnectedApp, UDWallet) {
        guard let connectedApp = WCConnectedAppsStorage.shared.find(by: [walletAddress], topic: request.url.topic)?.first,
              let udWallet = appContext.udWalletsService.find(by: walletAddress) else {
            Debugger.printFailure("No connected app can sign for the wallet address \(walletAddress) from request \(request)", critical: true)
            throw WalletConnectService.Error.failedToFindWalletToSign
        }
        return (connectedApp, udWallet)
    }
}

extension WalletConnectService: WCSigner {
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
                    .methodUnsupported: return .failedTx
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
    }
    
    var walletConnectClientService: WalletConnectClientServiceProtocol { appContext.walletConnectClientService }
        
    func handlePersonalSign(request: Request) {
        Task {
            do {
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
                    self.server.send(.invalid(request))
                    notifyDidHandleExternalWCRequestWith(result: .failure(error))
                    return
                }
                self.server.send(Response.signature(sig, for: request))
                notifyDidHandleExternalWCRequestWith(result: .success(()))
            } catch {
                Debugger.printFailure("Signing a message was interrupted: \(error.localizedDescription)")
                server.send(.invalid(request))
                notifyDidHandleExternalWCRequestWith(result: .failure(error))
            }
        }
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
    
    func handleSignTx(request: WalletConnectSwift.Request) {
        Task {
            do {
                let _tx = try request.parameter(of: EthereumTransaction.self, at: 0)
                
                
                guard let address = _tx.from?.hex(eip55: true).normalized else {
                    throw Error.failedToFindWalletToSign
                }
                
                let (connectedApp, udWallet) = try await getWalletAfterConfirmationIfNeeded(address: address,
                                                                                            request: request,
                                                                                            transaction: _tx)
                
                guard let chainIdInt = connectedApp.session.walletInfo?.chainId else {
                    Debugger.printFailure("Failed to find chainId for request: \(request)", critical: true)
                    throw Error.failedToDetermineChainId
                }
                let completedTx = try await completeTx(transaction: _tx, chainId: chainIdInt)

                
                let sig = try await udWallet.getTxSignature(ethTx: completedTx,
                                                            chainId: BigUInt(connectedApp.session.dAppInfo.getChainId()),
                                                            request: request)
                self.server.send(Response.signature(sig, for: request))
                self.notifyDidHandleExternalWCRequestWith(result: .success(()))
            } catch {
                let wcError = (error as? WalletConnectService.Error) ?? WalletConnectService.Error.failedToSignTransaction
                Debugger.printFailure("Failed to sign transaction, error=\(error)", critical: false)
                self.uiHandler?.didFailToConnect(with: wcError)
                self.server.send(.invalid(request))
                self.notifyDidHandleExternalWCRequestWith(result: .failure(error))
            }
        }
    }
    
    func handleEthSign(request: Request) {
        self.uiHandler?.didReceiveUnsupported(request.method)
        Debugger.printFailure("Unsupported WC method: \(request.method)")
        self.server.send(.invalid(request))
        notifyDidHandleExternalWCRequestWith(result: .failure(WalletConnectService.Error.methodUnsupported))
    }
        
    func handleSendTx(request: WalletConnectSwift.Request) {
        Task {
            do {
                let _transaction = try request.parameter(of: EthereumTransaction.self, at: 0)

                guard let walletAddress = _transaction.from?.hex(eip55: true) else {
                    throw Error.failedToFindWalletToSign
                }
                
                let (connectedApp, udWallet) = try detectConnectedApp(by: walletAddress, request: request)
                guard let chainIdInt = connectedApp.session.walletInfo?.chainId else {
                    self.server.send(.invalid(request))
                    Debugger.printFailure("Failed to find chainId for request: \(request)", critical: true)
                    return
                }

                let completedTx = try await completeTx(transaction: _transaction,  chainId: chainIdInt)

                let (_, _) = try await getWalletAfterConfirmationIfNeeded(address: walletAddress,
                                                                                    request: request,
                                                                                    transaction: completedTx)
                guard udWallet.walletState != .externalLinked else {
                    guard let sessionWithExtWallet = walletConnectClientService.findSessions(by: walletAddress).first else {
                        Debugger.printFailure("Failed to find session for WC", critical: false)
                        uiHandler?.didFailToConnect(with: .noWCSessionFound)
                        self.server.send(.invalid(request))
                        notifyDidHandleExternalWCRequestWith(result: .failure(WalletConnectService.Error.noWCSessionFound))
                        return
                    }
                    
                    proceedSendTxViaWC(by: udWallet, during: sessionWithExtWallet, in: request, transaction: completedTx)
                        .done { (result: Response) in
                            self.server.send(result)
                            Debugger.printInfo(topic: .WallectConnect, "Successfully sent TX via external wallet: \(udWallet.address)")
                        }.catch { error in
                            Debugger.printFailure("Failed to send TX: \(error.getTypedDescription())", critical: false)
                            self.server.send(.invalid(request))
                            self.notifyDidHandleExternalWCRequestWith(result: .failure(error))
                        }
                    return
                }
                
                try await sendTx(transaction: completedTx,
                                   request: request,
                                   udWallet: udWallet,
                                   chainIdInt: chainIdInt)
            } catch {
                Debugger.printFailure("Sending a TX was interrupted: \(error.localizedDescription)")
                if let err = error as? WalletConnectService.Error {
                    uiHandler?.didFailToConnect(with: err)
                }
                self.server.send(.invalid(request))
                self.notifyDidHandleExternalWCRequestWith(result: .failure(error))
            }
        }
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
                                chainIdInt: Int) async throws {
        
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
        
        try transaction.sign(with: privateKey, chainId: chainId).promise
            .then { tx in
                web3.eth.sendRawTransaction(transaction: tx) }
            .done { hash in
                guard let result = hash.ethereumValue().string else {
                    Debugger.printFailure("Failed to parse response from sending: \(transaction)")
                    self.server.send(.invalid(request))
                    return
                }
                self.server.send(Response.transaction(result, for: request))
                self.notifyDidHandleExternalWCRequestWith(result: .success(()))
            }.catch { error in
                Debugger.printFailure("Sending a TX was failed: \(error.localizedDescription)")
                self.server.send(.invalid(request))
                self.notifyDidHandleExternalWCRequestWith(result: .failure(error))
            }
    }
    
    func handleSendRawTx(request: WalletConnectSwift.Request) {
        // TODO: check if this is correct way of initialising Raw TX
        let tx = try? EthereumSignedTransaction(rlp: RLPItem(bytes: Data().bytes))
        
        
        self.uiHandler?.didReceiveUnsupported(request.method)
        Debugger.printFailure("Unsupported method: \(request.method)")
        self.server.send(.invalid(request))
    }
    
    func handleSignTypedData(request: WalletConnectSwift.Request) {
        Task {
            do {
                let walletAddress = try request.parameter(of: String.self, at: 0)
                let dataString = try request.parameter(of: String.self, at: 1)

                Debugger.printInfo(topic: .WallectConnect, "Incoming request with payload: \(request.jsonString)")
                
                let (_, udWallet) = try await self.getWalletAfterConfirmationIfNeeded(address: walletAddress,
                                                                                 request: request,
                                                                                 messageString: dataString)
                
                guard udWallet.walletState != .externalLinked else {
                    guard let sessionWithExtWallet = walletConnectClientService.findSessions(by: walletAddress).first else {
                        Debugger.printFailure("Failed to find session for WC", critical: false)
                        uiHandler?.didFailToConnect(with: .noWCSessionFound)
                        self.server.send(.invalid(request))
                        return
                    }

                    proceedSignTypedDataViaWC(by: udWallet, during: sessionWithExtWallet, in: request, dataString: dataString)
                        .done { (result: Response) in
                            self.server.send(result)
                            Debugger.printInfo(topic: .WallectConnect, "Successfully sent TX via Ext Wallet")
                            self.notifyDidHandleExternalWCRequestWith(result: .success(()))
                        }.catch { error in
                            Debugger.printFailure("Failed to send TX: \(error.getTypedDescription())", critical: true)
                            self.server.send(.invalid(request))
                        }
                    return
                }
                
                self.uiHandler?.didReceiveUnsupported(request.method)
                Debugger.printFailure("Unsupported method: \(request.method)")
                self.server.send(.invalid(request))
                self.notifyDidHandleExternalWCRequestWith(result: .failure(WalletConnectService.Error.methodUnsupported))
                return

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
                
            } catch {
                Debugger.printFailure("Signing a message was interrupted: \(error.localizedDescription)")
                server.send(.invalid(request))
            }
        }
    }
    
    func handleGetTransactionCount(request: Request) {
        Task {
            do {
                let walletAddress = try request.parameter(of: HexAddress.self, at: 0)
                guard let app = WCConnectedAppsStorage.shared.find(by: walletAddress),
                      let chainId = app.session.walletInfo?.chainId else {
                    self.server.send(.invalid(request))
                    Debugger.printFailure("Failed to find chainId for request: \(request)", critical: true)
                    return
                }
                guard let nonce = await fetchNonce(address: walletAddress, chainId: chainId) else {
                    self.server.send(.invalid(request))
                    return
                }
                self.server.send(Response.nonce(nonce, for: request))
            } catch {
                Debugger.printFailure("Fetching nonce was interrupted: \(error.localizedDescription)")
                self.server.send(.invalid(request))
            }
        }
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
                                     transaction: EthereumTransaction) -> Promise<Response> {
        let promise = udWallet.sendTxViaWalletConnect(session: session, tx: transaction)
            .then { (response: Response) -> Promise<Response> in
                if let error = response.error {
                    Debugger.printFailure("Error from the sending ext wallet: \(error)", critical: false)
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
        Task { try? await udWallet.launchExternalWallet() }
        return promise
    }
        
    private func proceedSignTypedDataViaWC(by udWallet: UDWallet,
                                     during session: Session,
                                     in request: Request,
                                     dataString: String) -> Promise<Response> {
        let promise = udWallet.signTypedDataViaWalletConnect(session: session,
                                                             walletAddress: udWallet.address,
                                                             message: dataString)
            .then { (response: Response) -> Promise<Response> in
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
        Task { try? await udWallet.launchExternalWallet() }
        return promise
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
