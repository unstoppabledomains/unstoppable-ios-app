//
//  FireblocksRPCMessageHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.03.2024.
//

import Foundation

protocol FireblocksRPCMessageHandler: NetworkBearerAuthorisationHeaderBuilder { }

extension FireblocksRPCMessageHandler {
    func passRPC(payload: String,
                 authToken: String,
                 response: @escaping (String?) -> (),
                 error: @escaping (String?) -> ()) {
        
        Task {
            do {
                logMPC("Will handle outgoing message: \(payload)")
                let body = RequestBody(message: payload)
                let headers = buildAuthBearerHeader(token: authToken)
                let request = try APIRequest(urlString: FB_UD_MPC.MPCNetwork.URLSList.rpcMessagesURL,
                                             body: body,
                                             method: .post,
                                             headers: headers)
                let data = try await NetworkService().makeAPIRequest(request)
                let responseMessage = String(data: data, encoding: .utf8)
                
                logMPC("Did handle outgoing message with response: \(responseMessage ?? "")")
                response(responseMessage)
            } catch let requestError {
                let errorMessage = requestError.localizedDescription
                logMPC("Did fail to handle outgoing message with error: \(errorMessage)")
                
                error(errorMessage)
            }
        }
    }
}

fileprivate struct RequestBody: Encodable {
    let message: String
}
