//
//  ViewPullUpViewModifierConfiguration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.01.2024.
//

import SwiftUI

struct ViewPullUpViewModifierConfiguration {
    @ViewBuilder var modifierBlock: (any View) -> any View
    
    func applyOnView(_ view: any View) -> any View {
        modifierBlock(view)
    }
}

// MARK: - Open methods
extension ViewPullUpViewModifierConfiguration {
    typealias ServerConnectConfigurationResult = Result<WalletConnectServiceV2.ConnectionUISettings, Error>
    typealias ServerConnectConfigurationResultCallback = (ServerConnectConfigurationResult)->()
    
    static func serverConnectConfirmationPullUp(connectionConfig: WCRequestUIConfiguration,
                                                topViewController: UIViewController,
                                                completion: @escaping ServerConnectConfigurationResultCallback) -> ViewPullUpViewModifierConfiguration {
        .init(modifierBlock: { view in
            AnyView(view).modifier(ServerConnectConfirmationPullUpModifier(connectionConfig: connectionConfig, topViewController: topViewController, completion: completion))
        })
    }
    
    private struct ServerConnectConfirmationPullUpModifier: ViewModifier {
        
        let connectionConfig: WCRequestUIConfiguration
        var topViewController: UIViewController
        @State var completion: ServerConnectConfigurationResultCallback?
        @State private var pullUp: ViewPullUpConfigurationType?
        @State private var baseSignTransactionView: BaseSignTransactionView?
        
        func body(content: Content) -> some View {
            content
                .viewPullUp($pullUp)
                .onAppear {
                    pullUp = .custom(.showServerConnectConfirmationPullUp(for: connectionConfig, updateSignTransactionViewBlock: { signTransactionView in
                        self.baseSignTransactionView = signTransactionView
                    },
                                                                          confirmationCallback: { [weak topViewController] connectionSettings in
                        Task {
                            guard let topViewController else { return }
                            
                            if connectionConfig.isSARequired {
                                do {
                                    try await appContext.authentificationService.verifyWith(uiHandler: topViewController, purpose: .confirm)
                                    finishWith(result: .success(connectionSettings))
                                }
                            } else {
                                finishWith(result: .success(connectionSettings))
                            }
                        }
                    }, domainButtonCallback: { [weak baseSignTransactionView, weak topViewController] domain in
                        Task {
                            do {
                                guard let topViewController else { return }
                                
                                let isSetForRR = await appContext.dataAggregatorService.isReverseResolutionSet(for: domain.name)
                                let selectedDomain = DomainDisplayInfo(domainItem: domain, isSetForRR: isSetForRR)
                                let newDomain = try await UDRouter().showSignTransactionDomainSelectionScreen(selectedDomain: selectedDomain,
                                                                                                              swipeToDismissEnabled: false,
                                                                                                              in: topViewController)
                                
                                let domain = try await appContext.dataAggregatorService.getDomainWith(name: newDomain.name)
                                baseSignTransactionView?.setDomainInfo(domain, isSelectable: true)
                            }
                        }
                    }))
                }
                .onDisappear {
                    finishWith(result: .failure(PullUpViewService.PullUpError.cancelled))
                }
        }
        
        func finishWith(result: ServerConnectConfigurationResult) {
            completion?(result)
            self.completion = nil
            self.pullUp = nil
        }
    }
    
}

