//
//  FireblocksRPCMessageHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import Foundation


final class FireblocksRPCMessageHandler: NetworkAuthorisedWithBearerService, FireblocksConnectorMessageHandler {
    
    let authToken: String
    let networkService = NetworkService()
    
    init(authToken: String) {
        self.authToken = authToken
    }
    
    func handleOutgoingMessage(payload: String,
                               response: @escaping (String?) -> (),
                               error: @escaping (String?) -> ()) {
        Task {
            do {
                logMPC("Will handle outgoing message: \(payload)")
                let headers = buildAuthBearerHeader()
                let body = payload.data(using: .utf8)
                let request = try APIRequest(urlString: MPCNetwork.URLSList.rpcMessagesURL,
                                             body: body,
                                             method: .post,
                                             headers: headers)
                let data = try await networkService.makeAPIRequest(request)
                let responseMessage = String(data: data, encoding: .utf8)
                
                logMPC("Did handle outgoing message with response: \(responseMessage)")
                response(responseMessage)
            } catch let requestError {
                let errorMessage = requestError.localizedDescription
                logMPC("Did fail to handle outgoing message with error: \(errorMessage)")
                
                error(errorMessage)
            }
        }
    }
    
}
