//
//  SettingsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2024.
//

import SwiftUI

struct SettingsView: View, ViewAnalyticsLogger {
    
    @Environment(\.userProfilesService) var userProfilesService
    
    @State private var profiles: [UserProfile] = []
    var analyticsName: Analytics.ViewName { .settings }

    var body: some View {
        contentView()
            .background(Color.backgroundDefault)
            .onReceive(userProfilesService.profilesPublisher.receive(on: DispatchQueue.main), perform: { profiles in
                self.profiles = profiles
            })
            .navigationTitle(String.Constants.settings.localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                
            }
    }
    
}

// MARK: - Private methods
private extension SettingsView {
    @ViewBuilder
    func contentView() -> some View {
        ScrollView {
            //        profilesListView()
            moreSection()
        }
        .padding()
    }
    
    @ViewBuilder
    func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.currentFont(size: 20, weight: .bold))
            .foregroundStyle(Color.foregroundDefault)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.leading)
    }
}

// MARK: - Profiles
private extension SettingsView {
    @ViewBuilder
    func profilesListView() -> some View {
        if !profiles.isEmpty {
            UDCollectionSectionBackgroundView {
                VStack(alignment: .center, spacing: 0) {
                    ForEach(profiles, id: \.id) { profile in
                        listViewFor(profile: profile)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(profile: UserProfile) -> some View {
        UDCollectionListRowButton(content: {
//            UserProfileSelectionRowView(profile: profile,
//                                        isSelected: profile.id == selectedProfile?.id)
//            .udListItemInCollectionButtonPadding()
        }, callback: {
//            UDVibration.buttonTap.vibrate()
//            presentationMode.wrappedValue.dismiss()
//            userProfilesService.setActiveProfile(profile)
//            logButtonPressedAnalyticEvents(button: .profileSelected, parameters: [.profileId : profile.id])
        })
        .padding(EdgeInsets(4))
    }
}

// MARK: - More
private extension SettingsView {
    @ViewBuilder
    func moreSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: String.Constants.more.localized())
            moreItemsList()
        }
    }
    
    var currentMoreItems: [MoreSectionItems] {
        var items: [MoreSectionItems] = [.security]
        #if TESTFLIGHT
        items.append(.testnet(isOn: User.instance.getSettings().isTestnetUsed, callback: setTestnet))
        #endif
        return items
    }
    
    @ViewBuilder
    func moreItemsList() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(currentMoreItems, id: \.id) { moreItem in
                    listViewFor(moreItem: moreItem)
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(moreItem: MoreSectionItems) -> some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: moreItem.title,
                           value: moreItem.value,
                           imageType: .uiImage(moreItem.icon),
                           imageStyle: .centred(foreground: .white, background: moreItem.backgroundColor, bordered: true),
                           rightViewStyle: moreItem.rightViewStyle)
                        .udListItemInCollectionButtonPadding()
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: moreItem.analyticsName)
        })
        .padding(EdgeInsets(4))
    }
    
    
    func setTestnet(on isOn: Bool) {
        var settings = User.instance.getSettings()
        switch isOn {
        case false: settings.networkType = .mainnet
        case true: settings.networkType = .testnet
        }
        User.instance.update(settings: settings)
        Storage.instance.cleanAllCache()
        appContext.firebaseParkedDomainsAuthenticationService.logOut()
        appContext.messagingService.logout()
        Task { await appContext.userDataService.getLatestAppVersion() }
        appContext.walletsDataService.didChangeEnvironment()
        appContext.notificationsService.updateTokenSubscriptions()
    }
    
}

// MARK: - Entities
private extension SettingsView {
    enum MoreSectionItems: Identifiable {
        var id: String {
            switch self {
            case .security:
                return "security"
            case .testnet:
                return "testnet"
            }
        }
        case security
        case testnet(isOn: Bool, callback: (Bool)->())
        
        var title: String {
            switch self {
            case .security:
                return String.Constants.settingsSecurity.localized()
            case .testnet:
                return "Testnet"
            }
        }
        
        var icon: UIImage {
            switch self {
            case .security:
                return UIImage(named: "settingsIconLock")!
            case .testnet:
                return UIImage(named: "settingsIconTestnet")!
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .security:
                return .brandDeepBlue
            case .testnet:
                return .brandSkyBlue
            }
        }
       
        var value: String? {
            switch self {
            case .security:
                return User.instance.getSettings().touchIdActivated ? (appContext.authentificationService.biometricsName ?? "") : String.Constants.settingsSecurityPasscode.localized()
            case .testnet:
                return nil
            }
        }
        
        var rightViewStyle: UDListItemView.RightViewStyle {
            switch self {
            case .security:
                return .chevron
            case .testnet(let isOn, let callback):
                return .toggle(isOn: isOn, callback: callback)
            }
        }
        
        enum ControlType {
            case empty, chevron(value: String?), switcher(isOn: Bool)
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .security:
                return .settingsSecurity
            case .testnet:
                return .settingsTestnet
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
