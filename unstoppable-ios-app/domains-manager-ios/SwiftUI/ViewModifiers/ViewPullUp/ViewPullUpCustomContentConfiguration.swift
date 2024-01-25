//
//  ViewPullUpCustomContentConfiguration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.01.2024.
//

import SwiftUI

struct ViewPullUpCustomContentConfiguration {
    @ViewBuilder var content: () -> any View
    let height: CGFloat
    let analyticName: Analytics.PullUp
    var additionalAnalyticParameters: Analytics.EventParameters = [:]
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
    
    struct ViewWrapper: UIViewRepresentable {
        
        var view: UIView
        
        func makeUIView(context: Context) -> some UIView {
            view
        }
       
        func updateUIView(_ uiView: UIViewType, context: Context) { }
    }
    

    @MainActor
    static func showServerConnectConfirmationPullUp(for connectionConfig: WCRequestUIConfiguration,
                                                    updateSignTransactionViewBlock: (BaseSignTransactionView)->(),
                                             confirmationCallback: @escaping ((WalletConnectServiceV2.ConnectionUISettings)->()),
                                             domainButtonCallback: @escaping ((DomainItem)->())) -> ViewPullUpCustomContentConfiguration {
        
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
        updateSignTransactionViewBlock(signTransactionView)
        signTransactionView.setRequireSA(connectionConfig.isSARequired)
        signTransactionView.pullUp = pullUp
        let chainIds = connectionConfiguration.appInfo.getChainIds().map({ String($0) }).joined(separator: ",")
        let analyticParameters: Analytics.EventParameters = [.wcAppName: connectionConfiguration.appInfo.getDappName(),
                                                             .hostURL: connectionConfiguration.appInfo.getDappHostName(),
                                                             .chainId: chainIds]
        
        
        signTransactionView.confirmationCallback = confirmationCallback
        signTransactionView.domainButtonCallback = domainButtonCallback
        
        return .init(content: {
            ViewWrapper(view: signTransactionView)
        },
                     height: selectionViewHeight,
                     analyticName: pullUp,
                     additionalAnalyticParameters: analyticParameters)
        
//        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
//            if case .payment = connectionConfig,
//               !UserDefaults.wcFriendlyReminderShown {
//                UserDefaults.wcFriendlyReminderShown = true
////                showWCFriendlyReminderPullUp(in: pullUpView)
//            }
//        }
    }
    
}
