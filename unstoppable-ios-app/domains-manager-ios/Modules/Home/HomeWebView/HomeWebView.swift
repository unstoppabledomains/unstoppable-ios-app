//
//  HomeWebView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.01.2024.
//

import SwiftUI

struct HomeWebView: View {
    
    let user: FirebaseUser
    @EnvironmentObject var tabRouter: HomeTabRouter
    @State private var isHeaderVisible: Bool = true
    @State private var isOtherScreenPresented: Bool = false
    @State private var navigationState: NavigationStateManager?
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            List {
                headerIconRowView()
                    .onAppearanceChange($isHeaderVisible)
                headerInfoView()
                HomeWalletActionsView(actionCallback: { action in
//                    viewModel.walletActionPressed(action)
                }, subActionCallback: { subAction in
//                    viewModel.walletSubActionPressed(subAction)
                })
                domainsListView()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onChange(of: isHeaderVisible) { newValue in
                withAnimation {
                    navigationState?.isTitleVisible =
                    !isOtherScreenPresented &&
                    !isHeaderVisible &&
                    tabRouter.tabViewSelection == .wallets
                }
            }
            .onChange(of: isOtherScreenPresented) { newValue in
                withAnimation {
                    navigationState?.isTitleVisible = !isOtherScreenPresented && !isHeaderVisible
                    tabRouter.isTabBarVisible = !isOtherScreenPresented
                }
            }
            .listStyle(.plain)
            .clearListBackground()
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeWalletNavigationDestination.self) { destination in
                viewFor(navigationDestination: destination)
                    .ignoresSafeArea()
                    .onAppearanceChange($isOtherScreenPresented)
            }
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    HomeSettingsNavButtonView()
                }
            })
            .refreshable {
//                try? await appContext.walletsDataService.refreshDataForWallet(viewModel.selectedWallet)
            }
        }, navigationStateProvider: { state in
            self.navigationState = state
            state.customTitle = titleView
        }, path: $tabRouter.walletViewNavPath)
    }
}

// MARK: - Private methods
private extension HomeWebView {
    
    @ViewBuilder
    func titleView() -> some View {
        HStack {
            headerIconView(size: 12)
                .squareFrame(20)
            Text(user.displayName)
                .font(.currentFont(size: 16, weight: .semibold))
                .foregroundStyle(Color.foregroundDefault)
                .lineLimit(1)
                .frame(height: 20)
        }
    }
    
    @ViewBuilder
    func headerIconView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .foregroundStyle(Color.backgroundSuccessEmphasis)
            Image.globeIcon
                .resizable()
                .squareFrame(size)
                .foregroundStyle(Color.foregroundOnEmphasis)
        }
    }
    
    @ViewBuilder
    func headerIconRowView() -> some View {
        headerIconView(size: 40)
        .squareFrame(80)
        .overlay {
            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(Color.backgroundDefault)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    func headerInfoView() -> some View {
        VStack(spacing: 8) {
            Text(user.displayName)
                .font(.currentFont(size: 16, weight: .medium))
                .truncationMode(.middle)
                .foregroundStyle(Color.foregroundSecondary)
                .frame(height: 24)
            Text(String.Constants.pluralNDomains.localized(1, 1))
                .font(.currentFont(size: 32, weight: .bold))
                .truncationMode(.middle)
                .foregroundStyle(Color.foregroundDefault)
                .frame(height: 24)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    func domainsListView() -> some View {
        Text("Hello")
    }
    
    @ViewBuilder
    func viewFor(navigationDestination: HomeWalletNavigationDestination) -> some View {
        if case .settings = navigationDestination {
            SettingsViewControllerWrapper()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    let user = FirebaseUser.init(email: "oleg@unstoppabledomains.com")
    let router = HomeTabRouter(accountState: .webAccount(user))

    return HomeWebView(user: user)
        .environmentObject(router)
}
