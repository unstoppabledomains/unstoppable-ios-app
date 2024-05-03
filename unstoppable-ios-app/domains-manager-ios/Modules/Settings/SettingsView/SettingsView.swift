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
            othersSection()
            footerView()
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

// MARK: - Other
private extension SettingsView {
    @ViewBuilder
    func othersSection() -> some View {
        otherItemsList()
        .padding(.top, 16)
    }
    
    @ViewBuilder
    func otherItemsList() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(SettingsItems.allCases, id: \.self) { moreItem in
                    listViewFor(otherItem: moreItem)
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(otherItem: SettingsItems) -> some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: otherItem.title,
                           titleColor: .foregroundAccent,
                           imageType: .uiImage(otherItem.icon),
                           imageStyle: .centred(offset: .init(8), foreground: .foregroundAccent, background: .clear, bordered: false))
            .padding(.init(horizontal: 12, vertical: 4))
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: otherItem.analyticsName)
        })
        .padding(EdgeInsets(4))
    }
}

// MARK: - Footer
private extension SettingsView {
    @ViewBuilder
    func footerView() -> some View {
        VStack(spacing: 0) {
            Text("You are Unstoppable!")
                .foregroundStyle(Color.foregroundDefault)
                .frame(height: 20)
            Text(UserDefaults.buildVersion)
                .foregroundStyle(Color.foregroundMuted)
                .frame(height: 20)
        }
        .font(.currentFont(size: 14, weight: .medium))
        .padding(.top, 24)
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
    
    enum SettingsItems: CaseIterable {
        case rateUs, learn, twitter, support, legal
        
        var title: String {
            switch self {
            case .rateUs:
                return String.Constants.rateUs.localized()
            case .learn:
                return String.Constants.settingsLearn.localized()
            case .twitter:
                return String.Constants.settingsFollowTwitter.localized()
            case .support:
                return String.Constants.settingsSupportNFeedback.localized()
            case .legal:
                return String.Constants.settingsLegal.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .rateUs:
                return .iconStar24
            case .learn:
                return UIImage(named: "settingsIconLearn")!
            case .twitter:
                return UIImage(named: "settingsIconTwitter")!
            case .support:
                return UIImage(named: "settingsIconFeedback")!
            case .legal:
                return UIImage(named: "settingsIconLegal")!
            }
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .rateUs:
                return .settingsRateUs
            case .learn:
                return .settingsLearn
            case .twitter:
                return .settingsTwitter
            case .support:
                return .settingsSupport
            case .legal:
                return .settingsLegal
            }
        }

    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
