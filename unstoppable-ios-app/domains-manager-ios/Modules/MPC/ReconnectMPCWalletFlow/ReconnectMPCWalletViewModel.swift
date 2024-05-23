//
//  ReconnectMPCWalletViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2024.
//

import SwiftUI

@MainActor
final class ReconnectMPCWalletViewModel: ObservableObject {
    
    private let reconnectData: MPCWalletReconnectData
    let reconnectResultCallback: ReconnectMPCWalletFlow.FlowResultCallback
    @Published var navPath: [ReconnectMPCWalletFlow.NavigationDestination] = []
    @Published var navigationState: NavigationStateManager?
    @Published var isLoading = false
    @Published var error: Error?
    private var credentials: MPCActivateCredentials?
    private var wallet: UDWallet { reconnectData.wallet }
    var walletAddress: String { wallet.address }
    
    init(reconnectData: MPCWalletReconnectData,
         reconnectResultCallback: @escaping ReconnectMPCWalletFlow.FlowResultCallback) {
        self.reconnectData = reconnectData
        self.reconnectResultCallback = reconnectResultCallback
    }
    
    func handleAction(_ action: ReconnectMPCWalletFlow.FlowAction) {
        Task {
            do {
                switch action {
                case .reImportWallet:
                    navPath.append(.enterCredentials(email: reconnectData.email))
                case .removeWallet:
                    appContext.udWalletsService.remove(wallet: wallet)
                    reconnectResultCallback(.removed)
                case .didEnterCredentials(let credentials):
                    self.credentials = credentials
                    navPath.append(.enterCode(email: credentials.email))
                case .didEnterCode(let code):
                    guard let credentials else { return }
                    
                    navPath.append(.activate(credentials: credentials, code: code))
                case .didActivate(let wallet):
                    navigationState?.dismiss = true
                    reconnectResultCallback(.reconnected)
                case .didRequestToChangeEmail:
                    credentials = nil
                    navPath.removeAll()
                }
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
}

