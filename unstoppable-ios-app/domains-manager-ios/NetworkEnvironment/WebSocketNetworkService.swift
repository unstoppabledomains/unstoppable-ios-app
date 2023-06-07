//
//  WebSocketNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation

final class WebSocketNetworkService: NSObject {
    
    typealias ConnectParameters = [String : Any]
    typealias OnEventCallback = (Data)->()
            
    init(connectionURL: URL, connectParams: ConnectParameters) {
        super.init()
        setupConnection(url: connectionURL, connectParams: connectParams)
    }
    
}

// MARK: - Open methods
extension WebSocketNetworkService {
    func connect() {
      
    }
    
    func on(_ event: String, callback: @escaping OnEventCallback) {
        
    }
    
    func disconnect() {
      
    }
}

// MARK: - Private methods
private extension WebSocketNetworkService {
  
}

// MARK: - Setup methods
private extension WebSocketNetworkService {
    func setupConnection(url: URL, connectParams: ConnectParameters) {
        
    }
}


