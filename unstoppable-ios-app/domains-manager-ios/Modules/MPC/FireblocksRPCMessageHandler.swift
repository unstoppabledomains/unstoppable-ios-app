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
                let headers = buildAuthBearerHeader()
                let body = payload.data(using: .utf8)
                let request = try APIRequest(urlString: MPCNetwork.URLSList.rpcMessagesURL,
                                             body: body,
                                             method: .post,
                                             headers: headers)
                let data = try await networkService.makeAPIRequest(request)
                let responseMessage = String(data: data, encoding: .utf8)
                
                response(responseMessage)
            } catch let requestError {
                let errorMessage = requestError.localizedDescription
                
                error(errorMessage)
            }
        }
    }
    
}
