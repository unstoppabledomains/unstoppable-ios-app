//
//  ViewPullUpCustomContentConfiguration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.01.2024.
//

import SwiftUI

struct ViewPullUpCustomContentConfiguration {
    let id = UUID()
    @ViewBuilder var content: () -> any View
    let height: CGFloat
    let analyticName: Analytics.PullUp
    var additionalAnalyticParameters: Analytics.EventParameters = [:]
    var dismissCallback: EmptyCallback? = nil
}

// MARK: - Open methods
extension ViewPullUpCustomContentConfiguration {
    static func loadingIndicator() -> ViewPullUpCustomContentConfiguration {
        .init(content: {
            ZStack {
                ProgressView()
                    .tint(Color.foregroundDefault)
            }
            .backgroundStyle(Color.backgroundDefault)
        },
              height: 428,
              analyticName: .wcLoading)
    }
    
}

// MARK: - Open methods
extension ViewPullUpCustomContentConfiguration {
    @MainActor
    static func serverConnectConfirmationPullUp(connectionConfig: WCRequestUIConfiguration,
                                                topViewController: UIViewController,
                                                completion: @escaping ServerConnectConfigurationResultCallback) -> ViewPullUpCustomContentConfiguration {
        let signTransactionView: BaseSignTransactionView
        let selectionViewHeight: CGFloat
        let pullUp: Analytics.PullUp
        let connectionConfiguration: WalletConnectServiceV2.ConnectionConfig
        let viewFrame: CGRect = UIScreen.main.bounds
        
        switch connectionConfig {
        case .signMessage(let configuration):
            let signMessageConfirmationView = SignMessageRequestConfirmationView(frame: viewFrame)
            signMessageConfirmationView.configureWith(configuration)
            selectionViewHeight = signMessageConfirmationView.requiredHeight()
            signTransactionView = signMessageConfirmationView
            pullUp = .wcRequestSignMessageConfirmation
            connectionConfiguration = configuration.connectionConfig
        case .payment(let configuration):
            let signPaymentConfirmationView = PaymentTransactionRequestConfirmationView(frame: viewFrame)
            signPaymentConfirmationView.configureWith(configuration)
            selectionViewHeight = configuration.isGasFeeOnlyTransaction ? 512 : 564
            signTransactionView = signPaymentConfirmationView
            pullUp = .wcRequestTransactionConfirmation
            connectionConfiguration = configuration.connectionConfig
        case .connectWallet(let connectionConfig):
            let connectServerConfirmationView = ConnectServerRequestConfirmationView(frame: viewFrame)
            connectServerConfirmationView.setWith(connectionConfig: connectionConfig)
            selectionViewHeight = 376
            signTransactionView = connectServerConfirmationView
            pullUp = .wcRequestConnectConfirmation
            connectionConfiguration = connectionConfig
        }
        
        signTransactionView.setRequireSA(connectionConfig.isSARequired)
        signTransactionView.pullUp = pullUp
        let chainIds = connectionConfiguration.appInfo.getChainIds().map({ String($0) }).joined(separator: ",")
        let analyticParameters: Analytics.EventParameters = [.wcAppName: connectionConfiguration.appInfo.getDappName(),
                                                             .hostURL: connectionConfiguration.appInfo.getDappHostName(),
                                                             .chainId: chainIds]
        //        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
        //            if case .payment = connectionConfig,
        //               !UserDefaults.wcFriendlyReminderShown {
        //                UserDefaults.wcFriendlyReminderShown = true
        ////                showWCFriendlyReminderPullUp(in: pullUpView)
        //            }
        //        }
        return .init(content: {
            ServerConnectConfirmationPullUpView(connectionConfig: connectionConfig,
                                                baseSignTransactionView: signTransactionView,
                                                topViewController: topViewController,
                                                completion: completion)
        }, height: selectionViewHeight,
              analyticName: pullUp,
              additionalAnalyticParameters: analyticParameters,
                     dismissCallback: {
            completion(.failure(PullUpViewService.PullUpError.cancelled))
        })
    }
    
    typealias ServerConnectConfigurationResult = Result<WalletConnectServiceV2.ConnectionUISettings, Error>
    typealias ServerConnectConfigurationResultCallback = (ServerConnectConfigurationResult)->()
    
    struct ServerConnectConfirmationPullUpView: View {
        
        let connectionConfig: WCRequestUIConfiguration
        let baseSignTransactionView: BaseSignTransactionView
        var topViewController: UIViewController
        @State var completion: ServerConnectConfigurationResultCallback?
        
        var body: some View {
            VStack {
                DismissIndicatorView()
                    .padding()

                wrappedContent()
            }
            .background(Color.backgroundDefault)
        }
        
        @MainActor
        @ViewBuilder
        func wrappedContent() -> some View {
            UIViewToViewWrapper(view: baseSignTransactionView)
                .onAppear(perform: {
                    baseSignTransactionView.confirmationCallback = { [weak topViewController] connectionSettings in
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
                    }
                    baseSignTransactionView.domainButtonCallback = { [weak baseSignTransactionView, weak topViewController] domain in
                        Task {
                            do {
                                guard let topViewController else { return }
                                
                                let isSetForRR = await appContext.dataAggregatorService.isReverseResolutionSet(for: domain.name)
                                let selectedDomain = DomainDisplayInfo(domainItem: domain, isSetForRR: isSetForRR)
                                let newDomain = try await UDRouter().showSignTransactionDomainSelectionScreen(selectedDomain: selectedDomain,
                                                                                                              swipeToDismissEnabled: false,
                                                                                                              in: topViewController)
                                
                                let domain = newDomain.toDomainItem()
                                baseSignTransactionView?.setDomainInfo(domain, isSelectable: true)
                            }
                        }
                    }
                })
        }

        func finishWith(result: ServerConnectConfigurationResult) {
            completion?(result)
            self.completion = nil
        }
    }
    
    struct UIViewToViewWrapper: UIViewRepresentable {
        
        var view: UIView
        
        func makeUIView(context: Context) -> some UIView {
            view
        }
        
        func updateUIView(_ uiView: UIViewType, context: Context) { }
    }
}
