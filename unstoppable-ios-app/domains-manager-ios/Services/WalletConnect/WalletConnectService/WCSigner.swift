//
//  WCSigner.swift
//  domains-manager-ios
//
//  Created by Roman on 02.07.2022.
//

import Foundation
import WalletConnectSwift
import Web3

typealias WCConnectionResult = Swift.Result<UnifiedConnectAppInfo, Swift.Error>
typealias WCConnectionResultCompletion = ((WCConnectionResult)->())
typealias WCAppDisconnectedCallback = ((UnifiedConnectAppInfo)->())

protocol WalletConnectV1RequestHandlingServiceProtocol {
    var appDisconnectedCallback: WCAppDisconnectedCallback? { get set }
    var willHandleRequestCallback: EmptyCallback? { get set }
    
    func registerRequestHandler(_ requestHandler: RequestHandler)
    func connectAsync(to requestURL: WCURL, completion: @escaping WCConnectionResultCompletion)
    func sendResponse(_ response: Response)
    func connectionTimeout()
    
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
            throw WalletConnectRequestError.failedToFindWalletToSign
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
  
    var walletConnectClientService: WalletConnectClientServiceProtocol { appContext.walletConnectClientService }
        
    func handlePersonalSign(request: Request) async throws -> Response {
        
        let incomingMessageString = try request.parameter(of: String.self, at: 0)
        let address = try request.parameter(of: String.self, at: 1)
        
        let readableMessageString = incomingMessageString.convertedIntoReadableMessage
        
        Debugger.printInfo(topic: .WallectConnect, "Incoming request with payload: \(request.jsonString)")
        
        let (_, udWallet) = try await getWalletAfterConfirmationIfNeeded(address: address,
                                                                         request: request,
                                                                         messageString: readableMessageString)
        let sig: String
        do {
            sig = try await udWallet.getPersonalSignature(messageString: incomingMessageString)
        } catch {
            //TODO: If the error == WalletConnectError.failedOpenExternalApp
            // the mobile wallet app may have been deleted
            
            Debugger.printFailure("Failed to sign message: \(incomingMessageString) by wallet:\(address)", critical: false)
            throw error
        }
        return Response.signature(sig, for: request)
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
        let _tx = try request.parameter(of: EthereumTransaction.self, at: 0)
        
        
        guard let address = _tx.from?.hex(eip55: true).normalized else {
            throw WalletConnectRequestError.failedToFindWalletToSign
        }
        
        let (connectedApp, udWallet) = try await getWalletAfterConfirmationIfNeeded(address: address,
                                                                                    request: request,
                                                                                    transaction: _tx)
        
        guard let chainIdInt = connectedApp.session.walletInfo?.chainId else {
            Debugger.printFailure("Failed to find chainId for request: \(request)", critical: true)
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        let completedTx = try await completeTx(transaction: _tx, chainId: chainIdInt)
        
        
        let sig = try await udWallet.getTxSignature(ethTx: completedTx,
                                                    chainId: BigUInt(connectedApp.session.dAppInfo.getChainId()),
                                                    request: request)
        return Response.signature(sig, for: request)
    }
    
    func handleEthSign(request: Request) async throws -> Response {
        throw WalletConnectRequestError.methodUnsupported
    }
        
    func handleSendTx(request: WalletConnectSwift.Request) async throws -> Response {
        let _transaction = try request.parameter(of: EthereumTransaction.self, at: 0)
        
        guard let walletAddress = _transaction.from?.hex(eip55: true) else {
            throw WalletConnectRequestError.failedToFindWalletToSign
        }
        
        let (connectedApp, udWallet) = try detectConnectedApp(by: walletAddress, request: request)
        guard let chainIdInt = connectedApp.session.walletInfo?.chainId else {
            Debugger.printFailure("Failed to find chainId for request: \(request)", critical: true)
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        
        let completedTx = try await completeTx(transaction: _transaction,  chainId: chainIdInt)
        
        let (_, _) = try await getWalletAfterConfirmationIfNeeded(address: walletAddress,
                                                                  request: request,
                                                                  transaction: completedTx)
        guard udWallet.walletState != .externalLinked else {
            guard let sessionWithExtWallet = walletConnectClientService.findSessions(by: walletAddress).first else {
                Debugger.printFailure("Failed to find session for WC", critical: false)
                throw WalletConnectRequestError.noWCSessionFound
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
                throw WalletConnectRequestError.failedFetchGas
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
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        let web3 = Web3(rpcURL: urlString)
        guard let privKeyString = udWallet.getPrivateKey() else {
            Debugger.printFailure("No private key in \(udWallet)", critical: true)
            throw WalletConnectRequestError.failedToGetPrivateKey
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
                        completion(.failure(WalletConnectRequestError.failedParseSendTxResponse))
                        return
                    }
                    let response = Response.transaction(result, for: request)
                    completion(.success(response))
                }.catch { error in
                    Debugger.printFailure("Sending a TX was failed: \(error.localizedDescription)")
                    completion(.failure(WalletConnectRequestError.failedSendTx))
                }
        })
    }
    
    func handleSendRawTx(request: WalletConnectSwift.Request) async throws -> Response {
        // TODO: check if this is correct way of initialising Raw TX
        let tx = try? EthereumSignedTransaction(rlp: RLPItem(bytes: Data().bytes))
        
        Debugger.printFailure("Unsupported method: \(request.method)")
        throw WalletConnectRequestError.methodUnsupported
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
                throw WalletConnectRequestError.noWCSessionFound
            }
            
            let response = try await proceedSignTypedDataViaWC(by: udWallet, during: sessionWithExtWallet, in: request, dataString: dataString)
            return response
        }
        
        throw WalletConnectRequestError.methodUnsupported
        
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
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        guard let nonce = await fetchNonce(address: walletAddress, chainId: chainId) else {
            throw WalletConnectRequestError.failedFetchNonce
        }
        return Response.nonce(nonce, for: request)
    }
    
    private func getWalletAfterConfirmationIfNeeded(address: HexAddress,
                                            request: Request,
                                            transaction: EthereumTransaction) async throws -> (WCConnectedAppsStorage.ConnectedApp, UDWallet) {
        guard let cost = TxDisplayDetails(tx: transaction) else { throw WalletConnectRequestError.failedToBuildCompleteTransaction }
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
                throw WalletConnectRequestError.uiHandlerNotSet
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
        let response = try await appContext.walletConnectExternalWalletHandler.sendTxViaWalletConnect_V1(session: session,
                                                                                                         tx: transaction,
                                                                                                         in: udWallet)
        
        let result = try response.result(as: String.self)
        return Response.transaction(result, for: request)
    }
    
    private func proceedSignTypedDataViaWC(by udWallet: UDWallet,
                                           during session: Session,
                                           in request: Request,
                                           dataString: String) async throws -> Response {
        let response = try await appContext.walletConnectExternalWalletHandler.signTypedDataViaWalletConnect_V1(session: session,
                                                                                                                walletAddress: udWallet.address,
                                                                                                                message: dataString,
                                                                                                                in: udWallet)
        let result = try response.result(as: String.self)
        return Response.transaction(result, for: request)
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
            throw WalletConnectRequestError.failedFetchNonce
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
                        completion(.failure(WalletConnectRequestError.failedFetchGas))
                        return
                    }
                    Debugger.printInfo(topic: .WallectConnect, "Fetched gas Estimate successfully: \(gasPriceString)")
                    completion(.success(result))
                case .rejected(let error):
                    if let jrpcError = error as? NetworkService.JRPCError {
                        switch jrpcError {
                        case .gasRequiredExceedsAllowance:
                            Debugger.printFailure("Failed to fetch gas Estimate because of Low Allowance Error", critical: false)
                            completion(.failure(WalletConnectRequestError.lowAllowance))
                            return
                        default: break
                        }
                    }
                    
                    Debugger.printFailure("Failed to fetch gas Estimate: \(error.localizedDescription)", critical: false)
                    completion(.failure(WalletConnectRequestError.failedFetchGas))
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
