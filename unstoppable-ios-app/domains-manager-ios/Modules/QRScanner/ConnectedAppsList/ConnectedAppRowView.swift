//
//  ConnectedAppRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import SwiftUI

struct ConnectedAppRowView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName: Analytics.ViewName
    
    let app: UnifiedConnectAppInfo
    
    @State private var appIcon: UIImage?
    @State private var appIconBackground: UIColor?
    
    var body: some View {
        HStack(spacing: 16) {
            iconView()
            appInfoView()
            Spacer()
            actionButton()
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension ConnectedAppRowView {
    func onAppear() {
        Task {
            let icon = await appContext.imageLoadingService.loadImage(from: .connectedApp(app, size: .default), downsampleDescription: .icon)
            let color = await ConnectedAppsImageCache.shared.colorForApp(app)
            
            appIconBackground = color
            appIcon = icon
        }
    }
    
    @ViewBuilder
    func iconView() -> some View {
        Image(uiImage: appIcon ?? .init())
            .resizable()
            .squareFrame(40)
            .background(Color(uiColor: appIconBackground ?? .clear))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: 0.5)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
    }
    
    @ViewBuilder
    func appInfoView() -> some View {
        VStack(alignment: .leading,
               spacing: 0) {
            Text(app.displayName)
                .textAttributes(color: .foregroundDefault,
                                fontSize: 16,
                                fontWeight: .medium)
                .frame(height: 24)
                .lineLimit(1)

            if let connectionDate = app.connectionStartDate {
                let formattedDate = DateFormattingService.shared.formatRecentActivityDate(connectionDate)
                Text(formattedDate)
                    .textAttributes(color: .foregroundSecondary,
                                    fontSize: 14,
                                    fontWeight: .medium)
                    .frame(height: 20)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
    
    var supportedNetworksNamesList: [String] {
        WalletConnectServiceV2.supportedNetworks.map({ $0.fullName })
    }
    
    @ViewBuilder
    func actionButton() -> some View {
        Menu {
            Section(app.displayName) {
                Button {
                    UDVibration.buttonTap.vibrate()
                    logButtonPressedAnalyticEvents(button: .connectedAppSupportedNetworks)
                    supportedNetworksButtonPressed()
                } label: {
                    Label(String.Constants.supportedNetworks.localized(), systemImage: "globe")
                    Text(supportedNetworksNamesList.joined(separator: ", "))
                }
            }
            Section {
                Button(role: .destructive) {
                    UDVibration.buttonTap.vibrate()
                    logButtonPressedAnalyticEvents(button: .disconnectApp)
                    disconnectButtonPressed()
                } label: {
                    Label(String.Constants.disconnect.localized(), systemImage: "xmark.circle")
                }
            }
        } label: {
            Image.dotsCircleIcon
                .resizable()
                .squareFrame(20)
                .foregroundStyle(Color.foregroundSecondary)
        }
        .onButtonTap()
    }
    
    func supportedNetworksButtonPressed() {
        Task { @MainActor in
            guard let topVC = appContext.coreAppCoordinator.topVC else { return }
            
            appContext.pullUpViewService.showConnectedAppNetworksInfoPullUp(in: topVC)
        }
    }
    
    func disconnectButtonPressed() {
        Task {
            try await appContext.walletConnectServiceV2.disconnect(app: app)
        }
    }
}
