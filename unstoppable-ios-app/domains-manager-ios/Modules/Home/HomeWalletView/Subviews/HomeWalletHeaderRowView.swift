//
//  HomeWalletHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletHeaderRowView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    @EnvironmentObject private var tabRouter: HomeTabRouter
    let wallet: WalletEntity
    let domainNamePressedCallback: MainActorCallback

    @State private var domainAvatar: UIImage?
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack {
                if wallet.portfolioRecords.count >= 2 {
                    WalletBalanceGradientChartView(chartData: wallet.portfolioRecords)
                        .padding(EdgeInsets(top: 0, leading: -16,
                                            bottom: 0, trailing: -16))
                }
                avatarView()
            }
                VStack(alignment: .center, spacing: 8) {
                    profileSelectionView()
                    totalBalanceView()
                }
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
    
    @ViewBuilder
    func avatarView() -> some View {
        getAvatarView()
            .squareFrame(80)
            .clipShape(Circle())
            .shadow(color: Color.backgroundDefault, radius: 24, x: 0, y: 0)
            .overlay {
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundStyle(Color.backgroundDefault)
            }
    }
    
    @ViewBuilder
    func getAvatarView() -> some View {
        if let domain = wallet.rrDomain {
            getAvatarViewForDomain(domain)
        } else {
            getAvatarViewToGetDomain()
        }
    }
    
    @ViewBuilder
    func getAvatarViewForDomain(_ domain: DomainDisplayInfo) -> some View {
        UIImageBridgeView(image: domainAvatar ?? .domainSharePlaceholder,
                          width: 20,
                          height: 20)
    }
    
    @ViewBuilder
    func getAvatarViewToGetDomain() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            tabRouter.runPurchaseFlow()
        } label: {
            ZStack {
                Circle()
                    .foregroundStyle(Color.backgroundWarning)
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
    func profileSelectionView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            domainNamePressedCallback()
        } label: {
            HStack(spacing: 0) {
                Text(getProfileSelectionTitle())
                    .font(.currentFont(size: 16, weight: .medium))
                Image.chevronGrabberVertical
                    .squareFrame(24)
            }
            .foregroundStyle(Color.foregroundSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func totalBalanceView() -> some View {
        Text("$\(wallet.totalBalance.formatted(toMaxNumberAfterComa: 2))")
            .titleText()
    }
}

#Preview {
    HomeWalletHeaderRowView(wallet: MockEntitiesFabric.Wallet.mockEntities().first!, 
                            domainNamePressedCallback: { })
}


import Charts

private struct WalletBalanceGradientChartView: View {
    struct ChartData: Hashable {
        let timestamp: Double
        let value: Double
    }

    
    let chartData: [WalletPortfolioRecord]
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
        .chartXScale(domain: chartData.first!.timestamp...chartData.last!.timestamp)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(maxWidth: .infinity)
    }
}
