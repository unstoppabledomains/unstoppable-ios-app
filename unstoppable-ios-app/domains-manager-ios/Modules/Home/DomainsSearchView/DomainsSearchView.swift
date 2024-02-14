//
//  DomainsSearchView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.02.2024.
//

import SwiftUI
import Combine

struct DomainsSearchView: View, ViewAnalyticsLogger {
    
    @Environment(\.walletsDataService) var walletsDataService
    @Environment(\.presentationMode) private var presentationMode

    typealias SearchProfilesTask = Task<[SearchDomainProfile], Error>
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @State private var currentTask: SearchProfilesTask?
    @State private var globalProfiles: [SearchDomainProfile] = []
    @State private var isLoadingGlobalProfiles = false
    @State private var searchText: String = ""
    @State private var searchKey: String = ""
    @State private var userDomains: [DomainDisplayInfo] = []
    @State private var domainsToShow: [DomainDisplayInfo] = []
    private let searchTextPublisher = PassthroughSubject<String, Never>()

    var analyticsName: Analytics.ViewName { .domainsSearch }
    
    var body: some View {
        NavigationStack {
            List {
                if domainsToShow.isEmpty && globalProfiles.isEmpty && !isLoadingGlobalProfiles {
                    if userDomains.isEmpty {
                        emptyStateFor(type: .noDomains)
                    } else {
                        emptyStateFor(type: .noResult)
                    }
                } else {
                    if !domainsToShow.isEmpty {
                        domainsSection(domainsToShow)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))

                    }
                    if !globalProfiles.isEmpty {
                        discoveredProfilesSection(globalProfiles)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
                    }
                }
            }.environment(\.defaultMinListRowHeight, 28)
            .listRowSpacing(0)
            .sectionSpacing(16)
            .clearListBackground()
            .background(Color.black)
            .animation(.default, value: UUID())
            .navigationTitle(String.Constants.allDomains.localized())
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: searchText) { searchText in
                searchTextPublisher.send(searchText)
            }
            .onReceive(
                searchTextPublisher
                    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            ) { debouncedSearchText in
                self.searchKey = debouncedSearchText.trimmedSpaces.lowercased()
                logAnalytic(event: .didSearch, parameters: [.value : searchKey])
                didSearchDomains()
            }
            .onAppear(perform: onAppear)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
}

// MARK: - Private methods
private extension DomainsSearchView {
    func onAppear() {
        userDomains = walletsDataService.wallets.combinedDomains().sorted(by: { $0.name < $1.name })
        domainsToShow = userDomains
    }
    
    @ViewBuilder
    func domainsSection(_ domains: [DomainDisplayInfo]) -> some View {
        sectionHeaderViewWith(title: String.Constants.yourDomains.localized())
            .listRowBackground(Color.clear)
        Section {
            ForEach(domains) { domain in
                domainsRowView(domain)
            }
        }
        .listRowBackground(Color.backgroundOverlay)
    }
    
    @ViewBuilder
    func domainsRowView(_ domain: DomainDisplayInfo) -> some View {
        UDCollectionListRowButton(content: {
            DomainSearchResultDomainRowView(domain: domain)
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logAnalytic(event: .domainPressed, parameters: [.domainName : domain.name])
            
            guard let wallet = walletsDataService.wallets.findOwningDomain(domain.name) else { return }
            
            Task {
                presentationMode.wrappedValue.dismiss()
                await Task.sleep(seconds: 0.3)
                await tabRouter.showDomainProfile(domain,
                                            wallet: wallet,
                                            preRequestedAction: nil,
                                            dismissCallback: nil)
            }
        })
    }
    
    @ViewBuilder
    func discoveredProfilesSection(_ profiles: [SearchDomainProfile]) -> some View {
        sectionHeaderViewWith(title: String.Constants.globalSearch.localized())
            .listRowBackground(Color.clear)
        Section {
            ForEach(profiles, id: \.name) { profile in
                discoveredProfileRowView(profile)
            }
        }
        .listRowBackground(Color.backgroundOverlay)
    }
    
    @ViewBuilder
    func discoveredProfileRowView(_ profile: SearchDomainProfile) -> some View {
        UDCollectionListRowButton(content: {
            DomainSearchResultProfileRowView(profile: profile)
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logAnalytic(event: .searchProfilePressed, parameters: [.domainName : profile.name])
            
            guard let walletAddress = profile.ownerAddress,
                  let selectedWallet = walletsDataService.selectedWallet else { return }
            presentationMode.wrappedValue.dismiss()

            let domainPublicInfo = PublicDomainDisplayInfo(walletAddress: walletAddress, name: profile.name)
            tabRouter.showPublicDomainProfile(of: domainPublicInfo, by: selectedWallet, preRequestedAction: nil)
        })
    }
    
    @ViewBuilder
    func sectionHeaderViewWith(title: String) -> some View {
        Text(title)
            .font(.currentFont(size: 14, weight: .medium))
            .foregroundStyle(Color.foregroundSecondary)
    }
    
    @ViewBuilder
    func emptyStateFor(type: EmptyStateType) -> some View {
        ZStack {
            VStack(spacing: 16) {
                Text(type.title)
                    .font(.currentFont(size: 22, weight: .bold))
                    .frame(height: 28)
                
                if let subtitle = type.subtitle {
                    Text(subtitle)
                        .font(.currentFont(size: 16))
                        .frame(height: 24)
                }
            }
            .foregroundStyle(Color.foregroundSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    enum EmptyStateType {
        case noDomains, noResult
        
        var title: String {
            switch self {
            case .noDomains:
                return "No domains in your wallet"
            case .noResult:
                return String.Constants.noResults.localized()
            }
        }
        
        
        var subtitle: String? {
            switch self {
            case .noDomains:
                return "Use the search to explore people's profiles."
            case .noResult:
                return nil
            }
        }
    }
    
}

// MARK: - Private methods
private extension DomainsSearchView {
    func didSearchDomains() {
        if searchKey.isEmpty {
            domainsToShow = userDomains 
        } else {
            domainsToShow = userDomains.filter({ $0.name.lowercased().contains(searchKey) })
        }
        globalProfiles.removeAll()
        scheduleSearchGlobalProfiles()
    }
    
    func scheduleSearchGlobalProfiles() {
        isLoadingGlobalProfiles = true
        Task {
            do {
                let profiles = try await searchForGlobalProfiles(with: searchKey)
                let userDomains = Set(self.userDomains.map({ $0.name }))
                self.globalProfiles = profiles.filter({ !userDomains.contains($0.name) && $0.ownerAddress != nil })
            }
            isLoadingGlobalProfiles = false
        }
    }
    
    func searchForGlobalProfiles(with searchKey: String) async throws -> [SearchDomainProfile] {
        // Cancel previous search task if it exists
        currentTask?.cancel()
        
        let task: SearchProfilesTask = Task.detached {
            do {
                try Task.checkCancellation()
                
                let profiles = try await self.searchForDomains(searchKey: searchKey)
                
                try Task.checkCancellation()
                return profiles
            } catch NetworkLayerError.requestCancelled, is CancellationError {
                return []
            } catch {
                throw error
            }
        }
        
        currentTask = task
        let users = try await task.value
        return users
    }
    
    func searchForDomains(searchKey: String) async throws -> [SearchDomainProfile] {
        if searchKey.isValidAddress() {
            let wallet = searchKey
            if let domain = try? await loadGlobalDomainRRInfo(for: wallet) {
                return [domain]
            }
            
            return []
        } else {
            let domains = try await NetworkService().searchForDomainsWith(name: searchKey, shouldBeSetAsRR: false)
            return domains
        }
    }
    
    func loadGlobalDomainRRInfo(for key: String) async throws -> SearchDomainProfile? {
        if let rrInfo = try? await NetworkService().fetchGlobalReverseResolution(for: key.lowercased()),
           rrInfo.name.isUDTLD() {
            
            return SearchDomainProfile(name: rrInfo.name,
                                       ownerAddress: rrInfo.address,
                                       imagePath: rrInfo.pfpURLToUse?.absoluteString,
                                       imageType: .offChain)
        }
        
        return nil
    }
}

#Preview {
    let router = HomeTabRouter(profile: .wallet(MockEntitiesFabric.Wallet.mockEntities().first!))
    return DomainsSearchView()
        .environmentObject(router)
}
