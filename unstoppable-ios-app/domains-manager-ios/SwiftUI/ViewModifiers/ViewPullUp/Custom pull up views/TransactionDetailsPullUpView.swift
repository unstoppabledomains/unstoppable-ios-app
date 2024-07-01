//
//  TransactionDetailsPullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.07.2024.
//

import SwiftUI

struct TransactionDetailsPullUpView: View {
    
    let tx: WalletTransactionDisplayInfo
    
    var body: some View {
        VStack(spacing: 0) {
            DismissIndicatorView()
                .padding(.vertical, 16)
            titleViews()
            txVisualisationsView()
                .padding(.top, 24)
            ZStack {
                curveLine()
                infoSectionsView()
            }
            viewTxButton()
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color.backgroundDefault)
    }
}

// MARK: - Private methods
private extension TransactionDetailsPullUpView {
    @ViewBuilder
    func titleViews() -> some View {
        VStack(spacing: 8) {
            Text("Sent successfully")
                .textAttributes(color: .foregroundDefault, fontSize: 22, fontWeight: .bold)
            HStack {
                Text(tx.time, style: .date)
                Text("·")
                Text(tx.time, style: .time)
            }
            .textAttributes(color: .foregroundSecondary, fontSize: 16)
        }
    }
    
    @ViewBuilder
    func txVisualisationsView() -> some View {
        ZStack {
            HStack(spacing: 8) {
                txItemVisualisationView()
                txReceiverVisualisationView()
            }
            ConnectTransactionSign()
                .rotationEffect(.degrees(-90))
        }
        .frame(height: 136)
    }
    
    @ViewBuilder
    func txItemVisualisationView() -> some View {
        BaseVisualisationView(title: "Item",
                              subtitle: "Item",
                              backgroundStyle: .plain) {
            Image.addWalletIcon
                .resizable()
        }
    }
    
    @ViewBuilder
    func txReceiverVisualisationView() -> some View {
        BaseVisualisationView(title: "Item",
                              subtitle: "Item",
                              backgroundStyle: .active(.success)) {
            Image.addWalletIcon
                .resizable()
        }
    }
    
    @MainActor
    @ViewBuilder
    func curveLine() -> some View {
        ConnectDarkCurveLine(numberOfSections: 4)
    }
    
    @MainActor
    @ViewBuilder
    func infoSectionsView() -> some View {
        VStack(spacing: 0) {
            ForEach(getCurrentSections(), id: \.self) { section in
                ConnectLineSectionView(section: section)
                    .frame(height: ConnectCurveLine.sectionHeight)
            }
        }
        .padding(.init(horizontal: 16))
    }
    
    func getCurrentSections() -> [ConnectLineSectionView.SectionType] {
        [.infoValue(.init(title: String.Constants.from.localized(),
                          icon: .walletExternalIcon,
                          value: "oleg.x")),
         .infoValue(.init(title: String.Constants.chain.localized(),
                          icon: chainIcon,
                          value: getBlockchainType()?.fullName ?? "")),
         .infoValue(.init(title: String.Constants.txFee.localized(),
                          icon: .gas,
                          value: "oleg.x"))]
    }
    
    func getBlockchainType() -> BlockchainType? {
        BlockchainType(rawValue: tx.symbol)
    }
    
    var chainIcon: UIImage {
        switch getBlockchainType() {
        case .Ethereum:
                .ethereumIcon
        default:
                .polygonIcon
        }
    }
    
    @ViewBuilder
    func viewTxButton() -> some View {
        if canViewTransaction {
            UDButtonView(text: String.Constants.viewTransaction.localized(),
                         style: .large(.raisedPrimary)) {
                
            }
        }
    }
    
    func openLink() {
        if let url = tx.link {
            //            openLink(.direct(url: url))
        }
    }
    
    var canViewTransaction: Bool {
        tx.link != nil
    }
}

// MARK: - Private methods
private extension TransactionDetailsPullUpView {
    struct BaseVisualisationView<C: View>: View {
        
        let title: String
        let subtitle: String
        let backgroundStyle: BackgroundStyle
        @ViewBuilder var iconContent: () -> C

        var body: some View {
            ZStack {
                if case .active = backgroundStyle {
                    Image.confirmSendTokenGrid
                        .resizable()
                }
                VStack(spacing: 16) {
                    iconContent()
                        .squareFrame(40)
                    VStack(spacing: 0) {
                        Text(title)
                            .frame(height: 24)
                            .textAttributes(color: .foregroundDefault, fontSize: 20, fontWeight: .medium)
                        Text(subtitle)
                            .frame(height: 24)
                            .textAttributes(color: .foregroundSecondary, fontSize: 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            .background(backgroundView())
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(borderColor)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        
        var borderColor: Color {
            switch backgroundStyle {
            case .plain:
                    .white.opacity(0.08)
            case .active(let activeBackgroundStyle):
                activeBackgroundStyle.borderColor
            }
        }
        
        @ViewBuilder
        func backgroundView() -> some View {
            switch backgroundStyle {
            case .plain:
                Color.backgroundOverlay
            case .active(let activeBackgroundStyle):
                activeBackgroundStyle.backgroundGradient
            }
        }
        
        enum BackgroundStyle {
            case plain
            case active(ActiveBackgroundStyle)
        }
        
        enum ActiveBackgroundStyle {
            case accent
            case success
            
            var borderColor: Color {
                switch self {
                case .accent:
                        .foregroundAccent
                case .success:
                        .foregroundSuccess
                }
            }
            
            var backgroundGradient: LinearGradient {
                switch self {
                case .accent:
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.05, green: 0.4, blue: 1).opacity(0), location: 0.25),
                            Gradient.Stop(color: Color(red: 0.05, green: 0.4, blue: 1).opacity(0.16), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                case .success:
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.05, green: 0.65, blue: 0.4).opacity(0), location: 0.25),
                            Gradient.Stop(color: Color(red: 0.05, green: 0.65, blue: 0.4).opacity(0.16), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                }
            }
        }
    }
}

#Preview {
    TransactionDetailsPullUpView(tx: .init(serializedTransaction: MockEntitiesFabric.WalletTxs.createMockTxOf(type: .crypto, userWallet: "1", isDeposit: false), userWallet: "1"))
}
