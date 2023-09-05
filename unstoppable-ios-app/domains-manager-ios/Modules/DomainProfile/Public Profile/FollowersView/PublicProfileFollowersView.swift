//
//  PublicProfileFollowersView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.08.2023.
//

import SwiftUI

typealias FollowerSelectionCallback = (DomainProfileFollowerDisplayInfo)->()

struct PublicProfileFollowersView: View {
    
    @MainActor
    static func instantiate(domainName: DomainName,
                            socialInfo: DomainProfileSocialInfo,
                            followerSelectionCallback: @escaping FollowerSelectionCallback,
                            isPresenting: Binding<Bool>) -> UIViewController {
        let view = PublicProfileFollowersView(domainName: domainName,
                                              socialInfo: socialInfo,
                                              followerSelectionCallback: followerSelectionCallback,
                                              isPresenting: isPresenting)
        let vc = UIHostingController(rootView: view)
        return vc
    }
    
    let followerSelectionCallback: FollowerSelectionCallback
    @Binding var isPresenting: Bool
    @StateObject private var viewModel: PublicProfileFollowersViewModel
    @State private var selectedFollower: DomainProfileFollowerDisplayInfo?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                PublicProfilePullUpHeaderView(domainName: viewModel.domainName,
                                              closeCallback: dismiss)
                Picker("", selection: $viewModel.selectedType) {
                    ForEach(DomainProfileFollowerRelationshipType.allCases, id: \.self) {
                        Text(titleFor(type: $0))
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if let currentFollowersList = viewModel.currentFollowersList,
                   !currentFollowersList.isEmpty {
                    ScrollViewReader { proxy in
                        List(getCurrentPublishedFollowersList() ?? [], id: \.domain, selection: $selectedFollower) { follower in
                            rowForFollower(follower)
                                .tag(follower)
                                .id(follower)
                                .listRowSeparator(.hidden)
                                .unstoppableListRowInset()
                                .onAppear {
                                    viewModel.loadMoreContentIfNeeded(currentFollower: follower)
                                }
                            
                            if viewModel.isLoadingPage,
                               follower == currentFollowersList.last {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .onChange(of: viewModel.selectedType) { _ in
                            proxy.scrollTo(currentFollowersList.first, anchor: .top)
                        }
                    }
                    
                    .offset(y: -8)
                    .background(.clear)
                    .clearListBackground()
                    .ignoresSafeArea()
                    .onChange(of: selectedFollower, perform: followerSelected)
                    
                } else {
                    Spacer()
                }
            }
            
            if let currentFollowersList = viewModel.currentFollowersList {
                if currentFollowersList.isEmpty {
                    currentEmptyView()
                }
            } else {
                ProgressView()
            }
        }
        .displayError($viewModel.error)
        .background(Color.backgroundDefault)
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: dismiss)
    }
    
    init(domainName: DomainName,
         socialInfo: DomainProfileSocialInfo,
         followerSelectionCallback: @escaping FollowerSelectionCallback,
         isPresenting: Binding<Bool>) {
        self.followerSelectionCallback = followerSelectionCallback
        self._isPresenting = isPresenting
        _viewModel = StateObject(wrappedValue: PublicProfileFollowersViewModel(domainName: domainName,
                                                                               socialInfo: socialInfo))
    }
    
}

// MARK: - Private methods
private extension PublicProfileFollowersView {
    func getCurrentPublishedFollowersList() -> [DomainProfileFollowerDisplayInfo]? {
        switch viewModel.selectedType {
        case .followers:
            return viewModel.followersList
        case .following:
            return viewModel.followingList
        }
    }
    
    func titleFor(type: DomainProfileFollowerRelationshipType) -> String {
        switch type {
        case .followers:
            return String.Constants.pluralNFollowers.localized(viewModel.socialInfo.followerCount).lowercased()
        case .following:
            return String.Constants.pluralNFollowing.localized(viewModel.socialInfo.followingCount).lowercased()
        }
    }
    
    func followerSelected(_ follower: DomainProfileFollowerDisplayInfo?) {
        guard let follower else { return }
        
        UDVibration.buttonTap.vibrate()
        dismiss()
        followerSelectionCallback(follower)
    }
    
    func dismiss() {
        guard isPresenting else { return }
        
        isPresenting = false
    }
}

// MARK: - Private methods
private extension PublicProfileFollowersView {
    @ViewBuilder
    func rowForFollower(_ follower: DomainProfileFollowerDisplayInfo) -> some View {
        HStack(spacing: 16) {
            Image(uiImage: follower.icon ?? .init())
                .resizable()
                .id(follower.icon)
                .frame(width: 40,
                       height: 40)
                .clipShape(Circle())
            Text(follower.domain)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundColor(.foregroundDefault)
                .lineLimit(1)
            Spacer()
            Image.cellChevron
                .resizable()
                .frame(width: 20,
                       height: 20)
                .foregroundColor(.foregroundSecondary)
        }
        .task {
            viewModel.loadIconIfNeededFor(follower: follower)
        }
    }
    
    @ViewBuilder
    func currentEmptyView() -> some View {
        VStack(spacing: 24) {
            Image.reputationIcon20
                .resizable()
                .frame(width: 48,
                       height: 48)
            
            Text(currentEmptyStateMessage())
                .font(.currentFont(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.foregroundSecondary)
        .padding()
    }
    
    func currentEmptyStateMessage() -> String {
        switch viewModel.selectedType {
        case .followers:
            return String.Constants.followersListEmptyMessage.localized(viewModel.domainName)
        case .following:
            return String.Constants.followingListEmptyMessage.localized(viewModel.domainName)
        }
    }
}

struct PublicProfileFollowersView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(Constants.swiftUIPreviewDevices, id: \.self) { device in
            PublicProfileFollowersView(domainName: "dans.crypto",
                                       socialInfo: .init(followingCount: 10, followerCount: 10001),
                                       followerSelectionCallback: { _ in },
                                       isPresenting: .constant(true))
            .previewDevice(PreviewDevice(rawValue: device))
            .previewDisplayName(device)
        }
    }
}
