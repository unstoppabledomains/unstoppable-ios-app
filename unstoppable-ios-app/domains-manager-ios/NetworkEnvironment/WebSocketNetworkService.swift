//
//  WebSocketNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation

final class WebSocketNetworkService: NSObject {
    
    private var socket: URLSessionWebSocketTask!
    
    let connectionURL: URL
    
    init(connectionURL: URL) {
        self.connectionURL = connectionURL
        super.init()
        setupConnection()
    }
    
}

// MARK: - Open methods
extension WebSocketNetworkService {
    func connect() {
        guard socket.state != .running else { return }
        
        socket.resume()
    }
    
    func disconnect() {
        guard socket.state == .running else { return }
        
        socket.cancel(with: .goingAway, reason: nil)
    }
}

// MARK: - Open methods
extension WebSocketNetworkService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connection opened")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket connection closed")
    }
}

// MARK: - Private methods
private extension WebSocketNetworkService {
    func sendMessage(_ message: String) {
        let messageData = message.data(using: .utf8)!
        socket.send(.data(messageData)) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
            } else {
                print("Message sent successfully")
            }
        }
    }
    
    func receiveMessages() {
        socket.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    if let message = String(data: data, encoding: .utf8) {
                        print("Received message: \(message)")
                    }
                default:
                    break
                }
                self.receiveMessages()
            case .failure(let error):
                print("Error receiving message: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Setup methods
private extension WebSocketNetworkService {
    func setupConnection() {
        let url = URL(string: "ws://localhost:3000")!
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        socket = session.webSocketTask(with: url)
        receiveMessages()
    }
}
