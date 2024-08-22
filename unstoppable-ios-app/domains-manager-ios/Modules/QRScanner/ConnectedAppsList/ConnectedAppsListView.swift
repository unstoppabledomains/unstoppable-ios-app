//
//  ConnectedAppsListView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import SwiftUI

struct ConnectedAppsListView: View, ViewAnalyticsLogger {
    
    var tabRouter: HomeTabRouter?

    @Environment(\.dismiss) private var dismiss
    var analyticsName: Analytics.ViewName { .wcConnectedAppsList }
    
    @State private var groupedApps: [GroupedConnectedApps] = []
    
    var body: some View {
        NavigationStack {
            contentView()
            .passViewAnalyticsDetails(logger: self)
            .trackAppearanceAnalytics(analyticsLogger: self)
            .background(Color.backgroundDefault)
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton()
                }
            }
            .onReceive(appContext.wcRequestsHandlingService.eventsPublisher.receive(on: DispatchQueue.main), perform: { event in
                handleWCEvent(event)
            })
            .navigationTitle(String.Constants.connectedAppsTitle.localized())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: onAppear)
        }
    }
}

// MARK: - Private methods
private extension ConnectedAppsListView {
    func onAppear() {
        refreshAppsList()
    }
    
    func refreshAppsList() {
        let connectedAppsUnified: [UnifiedConnectAppInfo] = appContext.walletConnectServiceV2.getConnectedApps()
        
        if connectedAppsUnified.isEmpty {
            self.groupedApps = []
            return
        }
        
        let wallets: [WalletEntity] = appContext.walletsDataService.wallets
        var groupedApps: [GroupedConnectedApps] = []
        
        // Fill snapshot
        let appsGroupedByWallet = [String : [UnifiedConnectAppInfo]].init(grouping: connectedAppsUnified,
                                                                                      by: { $0.walletAddress })
        
        for (walletAddress, apps) in appsGroupedByWallet {
            guard let wallet = wallets.findWithAddress(walletAddress),
                  !apps.isEmpty else { continue }
            
            let groupedApp = GroupedConnectedApps(wallet: wallet,
                                                  apps: apps)
            groupedApps.append(groupedApp)
        }
        
        self.groupedApps = groupedApps
    }
        
    func handleWCEvent(_ event: WalletConnectServiceEvent) {
        withAnimation {
            switch event {
            case .didConnect, .didDisconnect:
                refreshAppsList()
            default:
                return
            }
        }
    }
    
    struct GroupedConnectedApps: Identifiable {
        var id: String { wallet.address }
        
        let wallet: WalletEntity
        let apps: [UnifiedConnectAppInfo]
    }
}

// MARK: - Private methods
private extension ConnectedAppsListView {
    @ViewBuilder
    func closeButton() -> some View {
        CloseButtonView {
            logButtonPressedAnalyticEvents(button: .close)
            dismiss()
        }
    }
    
    @ViewBuilder
    func contentView() -> some View {
        if groupedApps.isEmpty {
            emptyStateView()
        } else {
            connectedAppsListView()
        }
    }
    
    @ViewBuilder
    func emptyStateView() -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image.widgetIcon
                    .resizable()
                    .squareFrame(32)
                    .foregroundStyle(Color.foregroundSecondary)
                Text(String.Constants.noConnectedApps.localized())
                    .textAttributes(color: .foregroundSecondary,
                                    fontSize: 20,
                                    fontWeight: .bold)
                    .frame(height: 24)
            }
            
            UDButtonView(text: String.Constants.scanToConnect.localized(),
                         icon: .qrBarCodeIcon,
                         style: .medium(.raisedPrimary)) {
                logButtonPressedAnalyticEvents(button: .scanToConnect)
                if let tabRouter {
                    tabRouter.showQRScanner()
                } else {
                    dismiss()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    func connectedAppsListView() -> some View {
        List {
            VStack {
                ForEach(groupedApps) { groupedApps in
                    sectionFor(groupedApps: groupedApps)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(0))
            .listRowSeparator(.hidden)
            .padding(.top, 32)
            .sectionSpacing(0)
            .listRowSpacing(0)
        }
    }
    
    @ViewBuilder
    func sectionFor(groupedApps: GroupedConnectedApps) -> some View {
        VStack(alignment: .leading) {
            sectionHeaderFor(wallet: groupedApps.wallet)
            sectionAppsList(groupedApps.apps)
        }
        .padding(.bottom, 32)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func sectionHeaderFor(wallet: WalletEntity) -> some View {
        Text(sectionHeaderTitleFor(wallet: wallet))
            .textAttributes(color: .foregroundSecondary,
                            fontSize: 14,
                            fontWeight: .medium)
            .frame(height: 20)
            .lineLimit(1)
    }
    
    func sectionHeaderTitleFor(wallet: WalletEntity) -> String {
        if let rrDomain = wallet.rrDomain {
            return rrDomain.name
        } else if wallet.displayInfo.isNameSet {
            return "\(wallet.displayName) (\(wallet.address.walletAddressTruncated))"
        }
        return wallet.address.walletAddressTruncated
    }
    
    @ViewBuilder
    func sectionAppsList(_ apps: [UnifiedConnectAppInfo]) -> some View {
        UDCollectionSectionBackgroundView {
            VStack {
                ForEach(apps, id: \.appName) { app in
                    ConnectedAppRowView(app: app)
                        .udListItemInCollectionButtonPadding()
                }
            }
            .padding(4)
        }
    }
}

#Preview {
    ConnectedAppsListView(tabRouter: nil)
}
