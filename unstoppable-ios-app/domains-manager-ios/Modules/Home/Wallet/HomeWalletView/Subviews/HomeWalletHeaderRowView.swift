//
//  HomeWalletHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletHeaderRowView: View, ViewAnalyticsLogger {
    
    @Environment(\.imageLoadingService) private var imageLoadingService
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    let wallet: WalletEntity
    let actionCallback: @MainActor (HomeWalletView.WalletAction)->()
    let didSelectDomainCallback: MainActorCallback
    let purchaseDomainCallback: MainActorCallback

    @State private var domainAvatar: UIImage?
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack(alignment: .center) {
                if wallet.portfolioRecords.count >= 2 {
                    WalletBalanceGradientChartView(chartData: wallet.portfolioRecords)
                        .padding(EdgeInsets(top: 0, leading: -16,
                                            bottom: 0, trailing: -16))
                        .frame(height: 92)
                }
                avatarView()
            }
            totalBalanceView()
        }
        .frame(maxWidth: .infinity)
        .onChange(of: wallet, perform: { wallet in
            loadAvatarFor(wallet: wallet)
        })
        .onAppear(perform: onAppear)
    }
    
}

// MARK: - Private methods
private extension HomeWalletHeaderRowView {
    func onAppear() {
        loadAvatarFor(wallet: wallet)
    }
    
    func loadAvatarFor(wallet: WalletEntity) {
        Task {
            if let domain = wallet.rrDomain,
               let image = await imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: .mid) {
                self.domainAvatar = image
            } else {
                self.domainAvatar = nil
            }
        }
    }
    
    @MainActor
    @ViewBuilder
    func avatarView() -> some View {
        ZStack(alignment: .bottom) {
            getAvatarView()
                .squareFrame(80)
                .clipShape(Circle())
                .shadow(color: Color.backgroundDefault, radius: 24, x: 0, y: 0)
                .overlay {
                    Circle()
                        .stroke(lineWidth: 2)
                        .foregroundStyle(Color.backgroundDefault)
                }
                .overlay {
                    if let state = resolveDomainState() {
                        Circle()
                            .trim(from: 0.0, to: 0.8)
                            .stroke(lineWidth: 2)
                            .rotationEffect(.degrees(130))
                            .padding(EdgeInsets(top: -2, leading: -2, bottom: -2, trailing: -2))
                            .foregroundStyle(state.tintColor)
                            .withoutAnimation()
                    }
                }
            getStatusView()
        }
    }
    
    @ViewBuilder
    func getStatusView() -> some View {
        if let state = resolveDomainState() {
            HStack(spacing: 4) {
                Image.refreshIcon
                    .resizable()
                    .squareFrame(16)
                    .infiniteRotation(duration: 5, angle: -360)
                Text(state.title)
                    .font(.currentFont(size: 12, weight: .medium))
            }
            .foregroundStyle(Color.black)
            .frame(height: 20)
            .padding(EdgeInsets(top: 2, leading: 4,
                                bottom: 2, trailing: 4))
            .overlay {
                Capsule()
                    .stroke(lineWidth: 3)
                    .foregroundStyle(Color.backgroundDefault)
            }
            .background(state.tintColor)
            .clipShape(Capsule())
        }
    }
 
    @MainActor
    @ViewBuilder
    func getAvatarView() -> some View {
        if let domain = wallet.rrDomain {
            getAvatarViewForDomain(domain)
        } else {
            getAvatarViewToGetDomain()
        }
    }
    
    @MainActor
    @ViewBuilder
    func getAvatarViewForDomain(_ domain: DomainDisplayInfo) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            didSelectDomainCallback()
            logButtonPressedAnalyticEvents(button: .rrDomainAvatar)
        } label: {
            UIImageBridgeView(image: domainAvatar ?? .domainSharePlaceholder)
        }
        .buttonStyle(.plain)
    }
    
    @MainActor
    @ViewBuilder
    func getAvatarViewToGetDomain() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            purchaseDomainCallback()
            logButtonPressedAnalyticEvents(button: .purchaseDomainAvatar)
        } label: {
            ZStack {
                Circle()
                    .foregroundStyle(Color.backgroundWarning)
                    .background(.ultraThinMaterial)
                VStack(spacing: 4) {
                    Image.plusIconNav
                        .resizable()
                        .squareFrame(20)
                    Text(String.Constants.domain.localized())
                        .font(.currentFont(size: 13, weight: .medium))
                        .frame(height: 20)
                }
                .foregroundStyle(Color.foregroundWarning)
            }
            
        }
        .buttonStyle(.plain)
    }
    
    func getProfileSelectionTitle() -> String {
        if let rrDomain = wallet.rrDomain {
            return rrDomain.name
        }
        return wallet.displayName
    }
    
    @ViewBuilder
    func totalBalanceView() -> some View {
        HStack(spacing: 8) {
            Text(BalanceStringFormatter.tokensBalanceUSDString(wallet.totalBalance))
                .titleText()
            receiveButtonView()
        }
    }
    
    @ViewBuilder
    func receiveButtonView() -> some View {
        UDButtonView(text: "",
                     icon: .arrowDown,
                     style: .small(.raisedTertiary)) {
            logButtonPressedAnalyticEvents(button: .receive)
            actionCallback(.receive)
        }
    }
}

// MARK: - Private methods
private extension HomeWalletHeaderRowView {
    enum DomainUpdatingState {
        case updating, transfer
        
        var tintColor: Color {
            switch self {
            case .updating:
                return .brandElectricYellow
            case .transfer:
                return .brandElectricGreen
            }
        }
        
        var title: String {
            switch self {
            case .updating:
                return String.Constants.updating.localized()
            case .transfer:
                return String.Constants.transferring.localized()
            }
        }
    }
    
    func resolveDomainState() -> DomainUpdatingState? {
        guard let domain = wallet.rrDomain else { return nil }
        switch domain.state {
        case .minting, .transfer:
            return .transfer
        case .updatingRecords, .updatingReverseResolution:
            return .updating
        default:
            return nil
        }
    }
}

#Preview {
    HomeWalletHeaderRowView(wallet: MockEntitiesFabric.Wallet.mockEntities().first!, 
                            actionCallback: { _ in  },
                            didSelectDomainCallback: { },
                            purchaseDomainCallback: { })
}


import Charts

private struct WalletBalanceGradientChartView: View {
    struct ChartData: Hashable {
        let timestamp: Double
        let value: Double
    }

    
    let chartData: [WalletPortfolioRecord]
    
    private let minX: Double
    private let maxX: Double
    private let maxY: Double
    
    private let linearGradient = LinearGradient(stops: [
        Gradient.Stop(color: Color(red: 0.2, green: 0.5, blue: 1).opacity(0.32), location: 0.00),
        Gradient.Stop(color: Color(red: 0.2, green: 0.5, blue: 1).opacity(0), location: 1.00),
    ],
                                        startPoint: UnitPoint(x: 0.5, y: 0),
                                        endPoint: UnitPoint(x: 0.5, y: 1))
    
    var body: some View {
        Chart {
            ForEach(chartData, id: \.self) { data in
                LineMark(x: .value("", data.timestamp),
                         y: .value("", data.value))
            }
            .interpolationMethod(.cardinal(tension: 0.4))
            .foregroundStyle(Color.foregroundAccent)
            
            ForEach(chartData, id: \.self) { data in
                AreaMark(x: .value("", data.timestamp),
                         y: .value("", data.value))
            }
            .interpolationMethod(.cardinal(tension: 0.4))
            .foregroundStyle(linearGradient)
        }
        .chartXScale(domain: minX...maxX)
        .chartYScale(domain: 0...maxY)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(maxWidth: .infinity)
        .withoutAnimation()
    }
    
    init(chartData: [WalletPortfolioRecord]) {
        self.chartData = chartData
        minX = chartData.first!.timestamp
        maxX = chartData.last!.timestamp
        
        let values = chartData.map { $0.value }
        maxY = values.max()!
    }
}

